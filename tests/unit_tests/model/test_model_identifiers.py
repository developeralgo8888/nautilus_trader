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

from nautilus_trader.model.identifiers import AccountId
from nautilus_trader.model.identifiers import Brokerage
from nautilus_trader.model.identifiers import ClientOrderId
from nautilus_trader.model.identifiers import Exchange
from nautilus_trader.model.identifiers import Identifier
from nautilus_trader.model.identifiers import Issuer
from nautilus_trader.model.identifiers import OrderId
from nautilus_trader.model.identifiers import PositionId
from nautilus_trader.model.identifiers import StrategyId
from nautilus_trader.model.identifiers import Symbol
from nautilus_trader.model.identifiers import TraderId
from nautilus_trader.model.identifiers import Venue


class IdentifierTests(unittest.TestCase):

    @parameterized.expand([
        [None, TypeError],
        ["", ValueError],
        [" ", ValueError],
        ["  ", ValueError],
        [1234, TypeError],
    ])
    def test_instantiate_given_various_invalid_values_raises_exception(self, value, ex):
        # Arrange
        # Act
        # Assert
        self.assertRaises(ex, Identifier, value)

    def test_equality(self):
        # Arrange
        id1 = Identifier("abc123")
        id2 = Identifier("abc123")
        id3 = Identifier("def456")

        # Act
        # Assert
        self.assertTrue("abc123", id1.value)
        self.assertTrue(id1 == id1)
        self.assertTrue(id1 == id2)
        self.assertTrue(id1 != id3)

    def test_equality_of_subclass(self):
        # Arrange
        id1 = Venue("BINANCE")
        id2 = Exchange("BINANCE")
        id3 = Symbol("BINANCE", Venue("BINANCE"))  # Invalid
        id4 = Brokerage("BINANCE")

        # Act
        # Assert
        self.assertTrue(id1 == id1)
        self.assertTrue(id2 == id2)
        self.assertTrue(id1 == id2)
        self.assertTrue(id2 == id1)
        self.assertTrue(id1 != id3)
        self.assertTrue(id2 != id3)
        self.assertTrue(id2 != id4)

    def test_comparison(self):
        # Arrange
        string1 = Identifier("123")
        string2 = Identifier("456")
        string3 = Identifier("abc")
        string4 = Identifier("def")

        # Act
        # Assert
        self.assertTrue(string1 <= string1)
        self.assertTrue(string1 <= string2)
        self.assertTrue(string1 < string2)
        self.assertTrue(string2 > string1)
        self.assertTrue(string2 >= string1)
        self.assertTrue(string2 >= string2)
        self.assertTrue(string3 <= string4)

    def test_hash(self):
        # Arrange
        identifier1 = Identifier("abc")
        identifier2 = Identifier("abc")

        # Act
        # Assert
        self.assertEqual(int, type(hash(identifier1)))
        self.assertEqual(hash(identifier1), hash(identifier2))

    def test_identifier_equality(self):
        # Arrange
        id1 = Identifier("some-id-1")
        id2 = Identifier("some-id-2")

        # Act
        result1 = id1 == id1
        result2 = id1 != id1
        result3 = id1 == id2
        result4 = id1 != id2

        # Assert
        self.assertTrue(result1)
        self.assertFalse(result2)
        self.assertFalse(result3)
        self.assertTrue(result4)

    def test_identifier_to_str(self):
        # Arrange
        identifier = Identifier("some-id")

        # Act
        result = str(identifier)

        # Assert
        self.assertEqual("some-id", result)

    def test_identifier_repr(self):
        # Arrange
        identifier = Identifier("some-id")

        # Act
        result = repr(identifier)

        # Assert
        self.assertEqual("Identifier('some-id')", result)

    def test_mixed_identifier_equality(self):
        # Arrange
        id1 = ClientOrderId("O-123456")
        id2 = PositionId("P-123456")

        # Act
        # Assert
        self.assertTrue(id1 == id1)
        self.assertFalse(id1 == id2)

    def test_symbol_equality(self):
        # Arrange
        symbol1 = Symbol("AUD/USD", Venue("SIM"))
        symbol2 = Symbol("AUD/USD", Venue('IDEAL_PRO'))
        symbol3 = Symbol("GBP/USD", Venue("SIM"))

        # Act
        # Assert
        self.assertTrue(symbol1 == symbol1)
        self.assertTrue(symbol1 != symbol2)
        self.assertTrue(symbol1 != symbol3)

    def test_symbol_str(self):
        # Arrange
        symbol = Symbol("AUD/USD", Venue("SIM"))

        # Act
        # Assert
        self.assertEqual("AUD/USD.SIM", str(symbol))

    def test_symbol_repr(self):
        # Arrange
        symbol = Symbol("AUD/USD", Venue("SIM"))

        # Act
        # Assert
        self.assertEqual("Symbol('AUD/USD.SIM')", repr(symbol))

    def test_parse_symbol_from_str(self):
        # Arrange
        symbol = Symbol("AUD/USD", Venue("SIM"))

        # Act
        result = Symbol.from_str(symbol.value)

        # Assert
        self.assertEqual(symbol, result)

    def test_account_id_given_malformed_string_raises_value_error(self):
        # Arrange
        # Act
        # Assert
        self.assertRaises(ValueError, AccountId.from_str, "BAD_STRING")

    def test_strategy_id_given_malformed_string_raises_value_error(self):
        # Arrange
        # Act
        # Assert
        self.assertRaises(ValueError, StrategyId.from_str, "BAD_STRING")

    def test_trader_id_given_malformed_string_raises_value_error(self):
        # Arrange
        # Act
        # Assert
        self.assertRaises(ValueError, TraderId.from_str, "BAD_STRING")

    def test_trader_identifier(self):
        # Arrange
        # Act
        trader_id1 = TraderId("TESTER", "000")
        trader_id2 = TraderId("TESTER", "001")

        # Assert
        self.assertEqual(trader_id1, trader_id1)
        self.assertNotEqual(trader_id1, trader_id2)
        self.assertEqual("TESTER-000", trader_id1.value)
        self.assertEqual("TESTER", trader_id1.name)
        self.assertEqual(trader_id1, TraderId.from_str("TESTER-000"))

    def test_strategy_identifier(self):
        # Arrange
        # Act
        strategy_id1 = StrategyId.null()
        strategy_id2 = StrategyId("SCALPER", "01")

        # Assert
        self.assertEqual("NULL-NULL", strategy_id1.value)
        self.assertEqual(strategy_id1, strategy_id1)
        self.assertNotEqual(strategy_id1, strategy_id2)
        self.assertEqual("NULL", strategy_id1.name)
        self.assertEqual(strategy_id2, StrategyId.from_str('SCALPER-01'))

    def test_account_identifier(self):
        # Arrange
        # Act
        account_id1 = AccountId("SIM", "02851908")
        account_id2 = AccountId("SIM", "09999999")

        # Assert
        self.assertEqual(account_id1, account_id1)
        self.assertNotEqual(account_id1, account_id2)
        self.assertEqual("SIM-02851908", account_id1.value)
        self.assertEqual(Issuer("SIM"), account_id1.issuer)
        self.assertEqual(account_id1, AccountId("SIM", "02851908"))

    def test_position_identifier(self):
        # Arrange
        # Act
        position_id0 = PositionId.null()

        # Assert
        self.assertEqual("NULL", position_id0.value)

    def test_order_identifier(self):
        # Arrange
        # Act
        order_id = OrderId.null()

        # Assert
        self.assertEqual("NULL", order_id.value)
