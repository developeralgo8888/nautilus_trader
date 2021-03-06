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

import unittest

from parameterized import parameterized

from nautilus_trader.core.cache import ObjectCache
from nautilus_trader.model.identifiers import Symbol


class ObjectCacheTests(unittest.TestCase):

    def test_cache_initialization(self):
        # Arrange
        cache = ObjectCache(Symbol, Symbol.from_str)

        # Act
        # Assert
        self.assertEqual(str, cache.type_key)
        self.assertEqual(Symbol, cache.type_value)
        self.assertEqual([], cache.keys())

    @parameterized.expand([
        [None, TypeError],
        ["", ValueError],
        [" ", ValueError],
        ["  ", ValueError],
        [1234, TypeError],
    ])
    def test_get_given_none_raises_value_error(self, value, ex):
        # Arrange
        cache = ObjectCache(Symbol, Symbol.from_str)

        # Act
        # Assert
        self.assertRaises(ex, cache.get, value)

    def test_get_from_empty_cache(self):
        # Arrange
        cache = ObjectCache(Symbol, Symbol.from_str)
        symbol = "AUD/USD.SIM"

        # Act
        result = cache.get(symbol)

        # Assert
        self.assertEqual(symbol, str(result))
        self.assertEqual(["AUD/USD.SIM"], cache.keys())

    def test_get_from_cache(self):
        # Arrange
        cache = ObjectCache(Symbol, Symbol.from_str)
        symbol = "AUD/USD.SIM"
        cache.get(symbol)

        # Act
        cache.get(symbol)
        result1 = cache.get(symbol)
        result2 = cache.get(symbol)

        # Assert
        self.assertEqual(symbol, str(result1))
        self.assertEqual(id(result1), id(result2))
        self.assertEqual(["AUD/USD.SIM"], cache.keys())

    def test_keys_when_cache_empty_returns_empty_list(self):
        # Arrange
        cache = ObjectCache(Symbol, Symbol.from_str)

        # Act
        result = cache.keys()

        # Assert
        self.assertEqual([], result)

    def test_clear_cache(self):
        # Arrange
        cache = ObjectCache(Symbol, Symbol.from_str)
        symbol = "AUD/USD.SIM"
        cache.get(symbol)

        # Act
        cache.clear()

        # Assert
        self.assertEqual([], cache.keys())
