# -------------------------------------------------------------------------------------------------
#  Copyright (C) 2015-2021 Nautech Systems Pty Ltd. All rights reserved.
#  https://nautechsystems.io
#
#  Licensed under the GNU Lesser General Public License Version 3.0 (the "License");
#  You may not use this file except in compliance with the License.
#  You may obtain a copy of the License at https://www.gnu.org/licenses/lgpl-3.0.en.html
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# -------------------------------------------------------------------------------------------------

from threading import Timer as TimerThread

from cpython.datetime cimport datetime
from cpython.datetime cimport timedelta

from nautilus_trader.common.timer cimport TimeEvent
from nautilus_trader.core.correctness cimport Condition
from nautilus_trader.core.datetime cimport format_iso8601
from nautilus_trader.core.message cimport Event
from nautilus_trader.core.uuid cimport UUID


cdef class TimeEvent(Event):
    """
    Represents a time event occurring at the event timestamp.
    """

    def __init__(
        self,
        str name not None,
        UUID event_id not None,
        datetime event_timestamp not None,
    ):
        """
        Initialize a new instance of the `TimeEvent` class.

        Parameters
        ----------
        name : str
            The event label.
        event_id : UUID
            The event identifier.
        event_timestamp : datetime
            The event timestamp.

        """
        Condition.valid_string(name, "name")
        super().__init__(event_id, event_timestamp)

        self.name = name

    def __eq__(self, TimeEvent other) -> bool:
        return self.name == other.name

    def __ne__(self, TimeEvent other) -> bool:
        return self.name != other.name

    def __repr__(self) -> str:
        return (f"{type(self).__name__}("
                f"name={self.name}, "
                f"id={self.id}, "
                f"timestamp={format_iso8601(self.timestamp)})")


cdef class TimeEventHandler:
    """
    Represents a bundled event and handler.
    """

    def __init__(self, TimeEvent event not None, handler not None: callable):
        self.event = event
        self._handler = handler

    cdef void handle(self) except *:
        self._handler(self.event)

    def __eq__(self, TimeEventHandler other) -> bool:
        return self.event.timestamp == other.event.timestamp

    def __ne__(self, TimeEventHandler other) -> bool:
        return self.event.timestamp != other.event.timestamp

    def __lt__(self, TimeEventHandler other) -> bool:
        return self.event.timestamp < other.event.timestamp

    def __le__(self, TimeEventHandler other) -> bool:
        return self.event.timestamp <= other.event.timestamp

    def __gt__(self, TimeEventHandler other) -> bool:
        return self.event.timestamp > other.event.timestamp

    def __ge__(self, TimeEventHandler other) -> bool:
        return self.event.timestamp >= other.event.timestamp

    def __repr__(self) -> str:
        return (f"{type(self).__name__}("
                f"event={self.event})")


cdef class Timer:
    """
    The abstract base class for all timers.

    This class should not be used directly, but through its concrete subclasses.
    """

    def __init__(
        self,
        str name not None,
        callback not None: callable,
        timedelta interval not None,
        datetime start_time not None,
        datetime stop_time=None,  # Can be None
    ):
        """
        Initialize a new instance of the `Timer` class.

        Parameters
        ----------
        name : str
            The name for the timer.
        callback : callable
            The function to call at the next time.
        interval : timedelta
            The time interval for the timer (not negative).
        start_time : datetime
            The start datetime for the timer (UTC).
        stop_time : datetime, optional
            The stop datetime for the timer (UTC) (if None then timer repeats).

        """
        Condition.valid_string(name, "name")
        Condition.callable(callback, "function")
        Condition.positive(interval.total_seconds(), "interval")
        if stop_time:
            Condition.true(start_time + interval <= stop_time, "start_time + interval <= stop_time")

        self.name = name
        self.callback = callback
        self.interval = interval
        self.start_time = start_time
        self.next_time = start_time + interval
        self.stop_time = stop_time
        self.expired = False

    def __eq__(self, Timer other) -> bool:
        return self.name == other.name

    def __ne__(self, Timer other) -> bool:
        return self.name != other.name

    def __hash__(self) -> int:
        return hash(self.name)

    def __repr__(self) -> str:
        return (f"{type(self).__name__}("
                f"name={self.name}, "
                f"interval={self.interval}, "
                f"start_time={self.start_time}, "
                f"next_time={self.next_time}, "
                f"stop_time={self.stop_time})")

    cpdef TimeEvent pop_event(self, UUID event_id):
        """
        Returns a generated time event with the given identifier.

        Parameters
        ----------
        event_id : UUID
            The identifier for the time event.

        """
        Condition.not_none(event_id, "event_id")

        return TimeEvent(self.name, event_id, self.next_time)

    cpdef void iterate_next_time(self, datetime now) except *:
        """
        Iterates the timers next time and checks if the timer is now expired.

        Parameters
        ----------
        now : datetime
            The datetime now (UTC).

        """
        Condition.not_none(now, "now")

        self.next_time += self.interval
        if self.stop_time and now >= self.stop_time:
            self.expired = True

    cpdef void cancel(self) except *:
        """Abstract method (implement in subclass)."""
        raise NotImplementedError("method must be implemented in the subclass")


cdef class TestTimer(Timer):
    """
    Provides a fake timer for backtesting and unit testing.
    """
    __test__ = False

    def __init__(
        self,
        str name not None,
        callback not None: callable,
        timedelta interval not None,
        datetime start_time not None,
        datetime stop_time=None
    ):
        """
        Initialize a new instance of the `TestTimer` class.

        Parameters
        ----------
        name : str
            The name for the timer.
        callback : callable
            The function to call at the next time.
        interval : timedelta
            The time interval for the timer (not negative).
        start_time : datetime
            The stop datetime for the timer (UTC).
        stop_time : datetime, optional
            The stop datetime for the timer (UTC) (if None then timer repeats).

        """
        Condition.valid_string(name, "name")
        super().__init__(name, callback, interval, start_time, stop_time)

        self._uuid_factory = UUIDFactory()

    cpdef list advance(self, datetime to_time):
        """
        Advance the test timer forward to the given time, generating a sequence
        of events. A time event is appended for each time a next event is
        <= the given to_time.

        Parameters
        ----------
        to_time : datetime
            The time to advance the test timer to.

        Returns
        -------
        list[TimeEvent]

        """
        Condition.not_none(to_time, "to_time")

        cdef list events = []  # type: list[TimeEvent]
        while not self.expired and to_time >= self.next_time:
            events.append(self.pop_event(self._uuid_factory.generate()))
            self.iterate_next_time(self.next_time)

        return events

    cpdef Event pop_next_event(self):
        """
        Return the next time event for this timer.

        Returns
        -------
        TimeEvent

        Raises
        ------
        ValueError
            If the next event timestamp is not equal to the at_time.

        """
        cdef TimeEvent event = self.pop_event(self._uuid_factory.generate())
        self.iterate_next_time(self.next_time)

        return event

    cpdef void cancel(self) except *:
        """
        Cancels the timer (the timer will not generate an event).
        """
        self.expired = True


cdef class LiveTimer(Timer):
    """
    Provides a timer for live trading.
    """

    def __init__(
        self,
        str name not None,
        callback not None: callable,
        timedelta interval not None,
        datetime now not None,
        datetime start_time not None,
        datetime stop_time=None,
    ):
        """
        Initialize a new instance of the `LiveTimer` class.

        Parameters
        ----------
        name : str
            The name for the timer.
        callback : callable
            The function to call at the next time.
        interval : timedelta
            The time interval for the timer.
        now : datetime
            The datetime now (UTC).
        start_time : datetime
            The start datetime for the timer (UTC).
        stop_time : datetime, optional
            The stop datetime for the timer (UTC) (if None then timer repeats).

        Raises
        ------
        TypeError
            If callback is not of type callable.

        """
        Condition.valid_string(name, "name")
        super().__init__(name, callback, interval, start_time, stop_time)

        self._internal = self._start_timer(now)

    cpdef void repeat(self, datetime now) except *:
        """
        Continue the timer.

        Parameters
        ----------
        now : datetime
            The current time to base the repeat from.

        """
        Condition.not_none(now, "now")

        self._internal = self._start_timer(now)

    cpdef void cancel(self) except *:
        """
        Cancels the timer (the timer will not generate an event).
        """
        self._internal.cancel()

    cdef object _start_timer(self, datetime now):
        timer = TimerThread(
            interval=(self.next_time - now).total_seconds(),
            function=self.callback,
            args=[self],
        )
        timer.daemon = True
        timer.start()

        return timer
