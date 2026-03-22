let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Prelude = Deps.Prelude

let Sdk = Deps.Sdk

let Compiled = Sdk.Compiled

let Input = Deps.Sdk.Project.QueryFragments

let Output
    : Type
    = { sqlExp : Text, docComment : Text }

let escapeRustString
    : Text -> Text
    = Prelude.Function.composeList
        Text
        [ Prelude.Text.replace "\\" "\\\\"
        , Prelude.Text.replace "\"" "\\\""
        , Prelude.Text.replace "\n" ("\\n\\\n")
        ]

let renderSqlExp
    : Deps.Sdk.Project.QueryFragments -> Text
    = \(fragments : Deps.Sdk.Project.QueryFragments) ->
            "\""
        ++  Prelude.Text.concatMap
              Deps.Sdk.Project.QueryFragment
              ( \(queryFragment : Deps.Sdk.Project.QueryFragment) ->
                  merge
                    { Sql = escapeRustString
                    , Var =
                        \(var : Deps.Sdk.Project.Var) ->
                          "\$" ++ Deps.Prelude.Natural.show (var.paramIndex + 1)
                    }
                    queryFragment
              )
              fragments
        ++  "\""

let renderDocComment
    : Deps.Sdk.Project.QueryFragments -> Text
    = Prelude.Text.concatMap
        Deps.Sdk.Project.QueryFragment
        ( \(queryFragment : Deps.Sdk.Project.QueryFragment) ->
            merge
              { Sql = Prelude.Function.identity Text
              , Var = \(var : Deps.Sdk.Project.Var) -> "\$" ++ var.rawName
              }
              queryFragment
        )

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        Compiled.ok
          Output
          { sqlExp = renderSqlExp input, docComment = renderDocComment input }

in  Algebra.module Input Output run
