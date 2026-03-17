module CalcDsl.Evaluator
    ( EvalError (..)
    , evaluate
    , renderValue
    ) where

import CalcDsl.Ast (Expr (..))
import Data.Ratio ((%), denominator, numerator)
import Data.Text (Text)
import qualified Data.Text as T
import Numeric (showFFloat)

data EvalError
    = DivisionByZero
    deriving (Eq, Show)

evaluate :: Expr -> Either EvalError Rational
evaluate expr =
    case expr of
        Number value ->
            Right (toInteger value % 1)
        Negate inner ->
            negate <$> evaluate inner
        Add lhs rhs ->
            (+) <$> evaluate lhs <*> evaluate rhs
        Subtract lhs rhs ->
            (-) <$> evaluate lhs <*> evaluate rhs
        Multiply lhs rhs ->
            (*) <$> evaluate lhs <*> evaluate rhs
        Divide lhs rhs -> do
            numeratorValue <- evaluate lhs
            denominatorValue <- evaluate rhs
            if denominatorValue == 0
                then Left DivisionByZero
                else Right (numeratorValue / denominatorValue)

renderValue :: Rational -> Text
renderValue value
    | denominator value == 1 = T.pack (show (numerator value))
    | otherwise = T.pack (trimTrailingZeros decimalText)
  where
    decimalText = showFFloat (Just 10) (fromRational value :: Double) ""

trimTrailingZeros :: String -> String
trimTrailingZeros raw =
    let withoutZeros = reverse (dropWhile (== '0') (reverse raw))
     in case reverse withoutZeros of
            '.':rest -> reverse rest
            _ -> withoutZeros
