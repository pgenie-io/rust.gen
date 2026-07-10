let Sdk = ../Deps/Sdk.dhall

let ResolvedTarget = ../ResolvedTarget.dhall

let Contract = ../Deps/Contract.dhall

let Lude = ../Deps/Lude.dhall

let Input = Contract.Name

let Output = { fieldName : Text }

let replaceTextIfEquals =
    -- Text/equal is not available in this environment. We get full-string
    -- equality out of the substring-based Text/replace by wrapping both sides
    -- in a sentinel ("|", which cannot occur in an identifier): "|target|" is a
    -- substring of "|original|" only when target == original, so the inner
    -- replace fires exactly on an exact match. The outer replace strips the
    -- sentinels back out.
      \(target : Text) ->
      \(replacement : Text) ->
      \(original : Text) ->
        let replacedWithSentinels =
              Text/replace "|${target}|" "|${replacement}|" "|${original}|"

        let replacedSansSentinels = Text/replace "|" "" replacedWithSentinels

        in  replacedSansSentinels

let replaceTextIfInList
    : List Text -> Text -> Text -> Text
    = \(candidates : List Text) ->
      \(replacement : Text) ->
        List/fold
          Text
          candidates
          Text
          (\(candidate : Text) -> replaceTextIfEquals candidate replacement)

let rustKeywords
    : List Text
    = [ "abstract"
      , "as"
      , "async"
      , "await"
      , "become"
      , "box"
      , "break"
      , "const"
      , "continue"
      , "crate"
      , "do"
      , "dyn"
      , "else"
      , "enum"
      , "extern"
      , "false"
      , "final"
      , "fn"
      , "for"
      , "if"
      , "impl"
      , "in"
      , "let"
      , "loop"
      , "macro"
      , "match"
      , "mod"
      , "move"
      , "mut"
      , "override"
      , "priv"
      , "pub"
      , "ref"
      , "return"
      , "self"
      , "static"
      , "struct"
      , "super"
      , "trait"
      , "true"
      , "type"
      , "typeof"
      , "try"
      , "union"
      , "unsafe"
      , "use"
      , "unsized"
      , "virtual"
      , "where"
      , "while"
      , "yield"
      ]

let escapeRustKeyword
    : Text -> Text
    = \(text : Text) -> replaceTextIfInList rustKeywords (text ++ "_") text

let run =
      \(config : ResolvedTarget.Type) ->
      \(input : Input) ->
        let fieldName = escapeRustKeyword input.inSnakeCase

        in  Lude.Compiled.ok Output { fieldName }

in  Sdk.Sigs.Interpreter.module ResolvedTarget.Type Input Output run
