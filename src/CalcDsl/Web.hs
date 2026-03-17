module CalcDsl.Web
    ( runServer
    ) where

import CalcDsl.Ast (prettyAst)
import CalcDsl.Evaluator (EvalError (DivisionByZero), evaluate, renderValue)
import CalcDsl.Parser (parseExpression)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Lazy as LT
import Text.Blaze.Html.Renderer.Text (renderHtml)
import qualified Text.Blaze.Html5 as H
import Text.Blaze.Html5 ((!), Html)
import qualified Text.Blaze.Html5.Attributes as A
import Web.Scotty (ScottyM, formParams, get, html, post, scotty, text)

data PageModel = PageModel
    { expressionInput :: Text
    , resultOutput :: Maybe Text
    , errorOutput :: Maybe Text
    , astOutput :: Maybe Text
    }

runServer :: Int -> IO ()
runServer port = do
    putStrLn ("haskell_calc_dsl is running at http://localhost:" <> show port)
    scotty port app

app :: ScottyM ()
app = do
    get "/" $
        html (renderPage emptyPageModel)

    post "/evaluate" $ do
        params <- formParams
        let expression = maybe "" id (lookup "expression" params)
        html (renderPage (evaluateExpression expression))

    get "/health" $
        text "ok"

emptyPageModel :: PageModel
emptyPageModel =
    PageModel
        { expressionInput = "1 + 2 * (3 + 4)"
        , resultOutput = Nothing
        , errorOutput = Nothing
        , astOutput = Nothing
        }

evaluateExpression :: Text -> PageModel
evaluateExpression expression =
    case parseExpression expression of
        Left parseError ->
            emptyPageModel
                { expressionInput = expression
                , errorOutput = Just (normalizeError parseError)
                , astOutput = Nothing
                , resultOutput = Nothing
                }
        Right ast ->
            case evaluate ast of
                Left DivisionByZero ->
                    emptyPageModel
                        { expressionInput = expression
                        , errorOutput = Just "Division by zero is not allowed."
                        , astOutput = Just (prettyAst ast)
                        , resultOutput = Nothing
                        }
                Right value ->
                    emptyPageModel
                        { expressionInput = expression
                        , errorOutput = Nothing
                        , astOutput = Just (prettyAst ast)
                        , resultOutput = Just (renderValue value)
                        }

normalizeError :: Text -> Text
normalizeError =
    T.strip . T.replace "expression:" ""

renderPage :: PageModel -> LT.Text
renderPage model =
    renderHtml $
        H.docTypeHtml $ do
            H.head $ do
                H.meta ! A.charset "utf-8"
                H.meta ! A.name "viewport" ! A.content "width=device-width, initial-scale=1"
                H.title "haskell_calc_dsl"
                H.style pageStyles
            H.body $ do
                H.main ! A.class_ "shell" $ do
                    H.section ! A.class_ "card" $ do
                        H.p ! A.class_ "eyebrow" $ "Haskell DSL"
                        H.h1 "haskell_calc_dsl"
                        H.p ! A.class_ "subtitle" $
                            "Parse arithmetic expressions, inspect the AST, and evaluate the result."
                        H.form ! A.method "post" ! A.action "/evaluate" ! A.class_ "stack" $ do
                            H.label ! A.for "expression" ! A.class_ "label" $ "Expression"
                            H.input
                                ! A.id "expression"
                                ! A.name "expression"
                                ! A.class_ "input"
                                ! A.value (H.toValue (expressionInput model))
                                ! A.placeholder "Type an expression like 1 + 2 * (3 + 4)"
                                ! A.autofocus ""
                            H.button ! A.class_ "button" ! A.type_ "submit" $ "Evaluate"
                        H.div ! A.class_ "examples" $ do
                            H.span ! A.class_ "muted" $ "Try:"
                            H.code "1 + 2 * (3 + 4)"
                            H.code "-8 + 3 * 2"
                            H.code "(12 - 4) / 2"
                        renderResult model

renderResult :: PageModel -> Html
renderResult model = do
    maybe mempty renderError (errorOutput model)
    maybe mempty renderValueCard (resultOutput model)
    maybe mempty renderAstCard (astOutput model)

renderError :: Text -> Html
renderError message =
    H.section ! A.class_ "panel panel-error" $ do
        H.h2 "Error"
        H.p (H.toHtml message)

renderValueCard :: Text -> Html
renderValueCard value =
    H.section ! A.class_ "panel panel-result" $ do
        H.h2 "Result"
        H.p ! A.class_ "result" $ H.toHtml value

renderAstCard :: Text -> Html
renderAstCard astText =
    H.section ! A.class_ "panel panel-ast" $ do
        H.h2 "AST"
        H.pre (H.toHtml astText)

pageStyles :: Html
pageStyles =
    H.preEscapedToHtml $
        T.unlines
            [ ":root {"
            , "  color-scheme: light;"
            , "  --bg: #f5f7fb;"
            , "  --card: #ffffff;"
            , "  --border: #dbe4f0;"
            , "  --text: #122033;"
            , "  --muted: #5d6b82;"
            , "  --accent: #1363df;"
            , "  --accent-soft: #eaf2ff;"
            , "  --success: #166534;"
            , "  --success-soft: #ecfdf3;"
            , "  --error: #b42318;"
            , "  --error-soft: #fef3f2;"
            , "}"
            , "* { box-sizing: border-box; }"
            , "body {"
            , "  margin: 0;"
            , "  min-height: 100vh;"
            , "  font-family: Segoe UI, Helvetica Neue, Arial, sans-serif;"
            , "  background: radial-gradient(circle at top, #ffffff 0%, var(--bg) 60%);"
            , "  color: var(--text);"
            , "}"
            , ".shell {"
            , "  max-width: 760px;"
            , "  margin: 0 auto;"
            , "  padding: 48px 20px;"
            , "}"
            , ".card {"
            , "  background: var(--card);"
            , "  border: 1px solid var(--border);"
            , "  border-radius: 24px;"
            , "  padding: 32px;"
            , "  box-shadow: 0 12px 40px rgba(18, 32, 51, 0.08);"
            , "}"
            , ".eyebrow {"
            , "  margin: 0 0 8px;"
            , "  color: var(--accent);"
            , "  font-size: 0.85rem;"
            , "  font-weight: 700;"
            , "  text-transform: uppercase;"
            , "  letter-spacing: 0.08em;"
            , "}"
            , "h1, h2 { margin: 0; }"
            , ".subtitle {"
            , "  margin: 12px 0 24px;"
            , "  color: var(--muted);"
            , "  line-height: 1.6;"
            , "}"
            , ".stack { display: grid; gap: 12px; }"
            , ".label { font-weight: 600; }"
            , ".input {"
            , "  width: 100%;"
            , "  border: 1px solid var(--border);"
            , "  border-radius: 14px;"
            , "  padding: 14px 16px;"
            , "  font-size: 1rem;"
            , "}"
            , ".button {"
            , "  width: fit-content;"
            , "  border: 0;"
            , "  border-radius: 14px;"
            , "  padding: 12px 20px;"
            , "  background: var(--accent);"
            , "  color: white;"
            , "  font-weight: 700;"
            , "  cursor: pointer;"
            , "}"
            , ".examples {"
            , "  display: flex;"
            , "  gap: 10px;"
            , "  flex-wrap: wrap;"
            , "  margin-top: 18px;"
            , "}"
            , ".examples code {"
            , "  background: #f1f5f9;"
            , "  border-radius: 999px;"
            , "  padding: 8px 12px;"
            , "}"
            , ".muted { color: var(--muted); }"
            , ".panel {"
            , "  margin-top: 20px;"
            , "  border-radius: 18px;"
            , "  padding: 18px 20px;"
            , "}"
            , ".panel-result {"
            , "  background: var(--success-soft);"
            , "  border: 1px solid #b7ebc6;"
            , "}"
            , ".panel-error {"
            , "  background: var(--error-soft);"
            , "  border: 1px solid #f8d3d0;"
            , "}"
            , ".panel-ast {"
            , "  background: #101828;"
            , "  color: #f8fafc;"
            , "}"
            , ".result {"
            , "  margin-top: 10px;"
            , "  font-size: 2rem;"
            , "  font-weight: 800;"
            , "}"
            , "pre {"
            , "  margin: 10px 0 0;"
            , "  white-space: pre-wrap;"
            , "  font-family: Consolas, Monaco, monospace;"
            , "}"
            , "@media (max-width: 640px) {"
            , "  .card { padding: 24px; }"
            , "  .shell { padding: 24px 14px; }"
            , "  .button { width: 100%; }"
            , "}"
            ]
