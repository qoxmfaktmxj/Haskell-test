module CalcDsl.Parser
    ( parseExpression
    ) where

import CalcDsl.Ast (Expr (..))
import Control.Applicative ((<|>))
import Control.Monad.Combinators.Expr
import Data.Text (Text)
import qualified Data.Text as T
import Data.Void (Void)
import Text.Megaparsec (Parsec, between, eof, errorBundlePretty, parse)
import Text.Megaparsec.Char (space1)
import qualified Text.Megaparsec.Char.Lexer as L

type Parser = Parsec Void Text

parseExpression :: Text -> Either Text Expr
parseExpression input =
    case parse (sc *> exprParser <* eof) "expression" input of
        Left bundle ->
            Left (T.pack (errorBundlePretty bundle))
        Right expr ->
            Right expr

exprParser :: Parser Expr
exprParser =
    makeExprParser term operatorTable

term :: Parser Expr
term =
    parens exprParser <|> number

number :: Parser Expr
number =
    Number <$> lexeme L.decimal

operatorTable :: [[Operator Parser Expr]]
operatorTable =
    [ [Prefix (Negate <$ symbol "-")]
    , [ InfixL (Multiply <$ symbol "*")
      , InfixL (Divide <$ symbol "/")
      ]
    , [ InfixL (Add <$ symbol "+")
      , InfixL (Subtract <$ symbol "-")
      ]
    ]

parens :: Parser a -> Parser a
parens =
    between (symbol "(") (symbol ")")

lexeme :: Parser a -> Parser a
lexeme =
    L.lexeme sc

symbol :: Text -> Parser Text
symbol =
    L.symbol sc

sc :: Parser ()
sc =
    L.space space1 lineComment blockComment
  where
    lineComment = L.skipLineComment "//"
    blockComment = L.skipBlockComment "/*" "*/"
