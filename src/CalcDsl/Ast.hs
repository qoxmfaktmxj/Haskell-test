module CalcDsl.Ast
    ( Expr (..)
    , prettyAst
    ) where

import Data.Text (Text)
import qualified Data.Text as T

data Expr
    = Number Integer
    | Negate Expr
    | Add Expr Expr
    | Subtract Expr Expr
    | Multiply Expr Expr
    | Divide Expr Expr
    deriving (Eq, Show)

prettyAst :: Expr -> Text
prettyAst = go 0
  where
    go :: Int -> Expr -> Text
    go depth expr =
        let pad = T.replicate depth "  "
         in case expr of
                Number value ->
                    pad <> "Number " <> T.pack (show value)
                Negate inner ->
                    T.intercalate "\n"
                        [ pad <> "Negate"
                        , go (depth + 1) inner
                        ]
                Add lhs rhs ->
                    branch depth "Add" lhs rhs
                Subtract lhs rhs ->
                    branch depth "Subtract" lhs rhs
                Multiply lhs rhs ->
                    branch depth "Multiply" lhs rhs
                Divide lhs rhs ->
                    branch depth "Divide" lhs rhs

    branch :: Int -> Text -> Expr -> Expr -> Text
    branch depth label lhs rhs =
        T.intercalate "\n"
            [ T.replicate depth "  " <> label
            , go (depth + 1) lhs
            , go (depth + 1) rhs
            ]
