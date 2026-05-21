let Algebra = ../Algebras/Interpreter.dhall

let Prelude = ../Deps/Prelude.dhall

let Project = ../Deps/Project.dhall

let Lude = ../Deps/Lude.dhall

let Input = Project.Name

let Output = { fieldName : Text }

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

let isRustKeyword =
      \(name : Input) ->
        Prelude.List.any
          Text
          (\(kw : Text) -> Text/equal kw name.inSnakeCase)
          rustKeywords

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        let rawFieldName = input.inSnakeCase

        let fieldName =
              if isRustKeyword input then rawFieldName ++ "_" else rawFieldName

        in  Lude.Compiled.ok Output { fieldName }

in  Algebra.module Input Output run
