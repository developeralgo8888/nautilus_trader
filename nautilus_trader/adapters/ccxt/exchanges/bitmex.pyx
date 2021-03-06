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

from nautilus_trader.core.correctness cimport Condition
from nautilus_trader.model.c_enums.liquidity_side cimport LiquiditySide
from nautilus_trader.model.c_enums.order_type cimport OrderType
from nautilus_trader.model.c_enums.time_in_force cimport TimeInForce
from nautilus_trader.model.order cimport Order


cdef class BitmexOrderRequestBuilder:

    @staticmethod
    cdef dict build(Order order):
        """
        Build the CCXT arguments and custom parameters to create the given order.

        Parameters
        ----------
        order : Order
            The order for the request.

        Returns
        -------
        dict[str, object]
            The arguments for the create order request.

        """
        Condition.not_none(order, "order")

        if order.time_in_force == TimeInForce.GTD:
            raise ValueError("GTD not supported in this version.")

        cdef dict params = {
            "clOrdID": order.cl_ord_id.value,
        }

        cdef str exec_inst = None
        if order.type == OrderType.MARKET:
            params["type"] = "Market"
        elif order.type == OrderType.LIMIT:
            params["type"] = "Limit"
            # Execution instructions
            if order.is_post_only:
                exec_inst = "ParticipateDoNotInitiate"
            elif order.is_hidden:
                params["displayQty"] = 0
            if order.is_reduce_only:
                if exec_inst is not None:
                    exec_inst += ",ReduceOnly"
                else:
                    exec_inst = "ReduceOnly"
            if exec_inst is not None:
                params["execInst"] = exec_inst
        elif order.type == OrderType.STOP_MARKET:
            params["type"] = "StopMarket"
            params["stopPx"] = str(order.price)
            if order.is_reduce_only:
                params["execInst"] = "ReduceOnly"

        if order.time_in_force == TimeInForce.DAY:
            params["timeInForce"] = "Day"
        elif order.time_in_force == TimeInForce.GTC:
            params["timeInForce"] = "GoodTillCancel"
        elif order.time_in_force == TimeInForce.IOC:
            params["timeInForce"] = "ImmediateOrCancel"
        elif order.time_in_force == TimeInForce.FOK:
            params["timeInForce"] = "FillOrKill"

        return params

    @staticmethod
    def build_py(Order order):
        """
        Build the CCXT arguments and custom parameters to create the given order.

        Wraps the `build` method for testing and access from pure Python. For
        best performance use the C access `build` method.

        Parameters
        ----------
        order : Order
            The order to build.

        Returns
        -------
        list[object], dict[str, object]
            The arguments and custom parameters.

        """
        return BitmexOrderRequestBuilder.build(order)


cdef class BitmexOrderFillParser:

    @staticmethod
    cdef dict parse(dict report):
        """
        Parse the information needed to generate an `OrderFilled` event from the
        given parameters.

        Parameters
        ----------
        report : dict[str, object]
            The execution report.

        Returns
        -------
        dict[str, object]
            The parsed information.

        """
        Condition.not_none(report, "report")

        cdef double exec_comm = report.get("execComm", 0) / 0.00000001  # Commission in XBt (Satoshi)
        cdef int liq_side = LiquiditySide.TAKER if report["lastLiquidityInd"] == "RemovedLiquidity" else LiquiditySide.MAKER
        return {
            "exec_id": report["execID"],
            "symbol": report["symbol"],
            "fill_qty": report["lastQty"],
            "cum_qty": report["cumQty"],
            "avg_px": report["lastPx"],
            "liquidity_side": liq_side,
            "commission": exec_comm,
            "commission_currency": "BTC",
            "timestamp": report["timestamp"],
        }

    @staticmethod
    def parse_py(dict report):
        """
        Parse the information needed to generate an order filled event from the
        given parameters.

        Parameters
        ----------
        report : dict[str, object]
            The execution report.

        Returns
        -------
        OrderFilled

        """
        return BitmexOrderFillParser.parse(report)
