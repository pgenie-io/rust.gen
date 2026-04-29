let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Project = ../Deps/Project.dhall

let Compiled = Lude.Compiled

let Input = Project.QueryFragments

let Output
    : Type
    = { mkSqlExp : List Text -> Text, docComment : Text }

let escapeRustString
    : Text -> Text
    = Prelude.Function.composeList
        Text
        [ Prelude.Text.replace "\\" "\\\\"
        , Prelude.Text.replace "\"" "\\\""
        , Prelude.Text.replace
            "\n"
            ''
            \n\
            ''
        ]

let quotePostgresKeywordCasts
    : Text -> Text
    = Prelude.Function.composeList
        Text
        [ Prelude.Text.replace "::char" "::\\\"char\\\"" ]

let renderSqlExp
    : Project.QueryFragments -> List Text -> Text
    = \(fragments : Project.QueryFragments) ->
      \(castSuffixes : List Text) ->
        let rawSql
            : Text
            =     "\""
              ++  Prelude.Text.concatMap
                    Project.QueryFragment
                    ( \(queryFragment : Project.QueryFragment) ->
                        merge
                          { Sql = escapeRustString
                          , Var =
                              \(var : Project.Var) ->
                                let suffix =
                                      Prelude.Optional.fold
                                        Text
                                        ( Prelude.List.index
                                            var.paramIndex
                                            Text
                                            castSuffixes
                                        )
                                        Text
                                        (\(s : Text) -> s)
                                        ""

                                in      "\$"
                                    ++  Prelude.Natural.show
                                          (var.paramIndex + 1)
                                    ++  suffix
                          }
                          queryFragment
                    )
                    fragments
              ++  "\""

        in  quotePostgresKeywordCasts rawSql

let renderDocComment
    : Project.QueryFragments -> Text
    = Prelude.Text.concatMap
        Project.QueryFragment
        ( \(queryFragment : Project.QueryFragment) ->
            merge
              { Sql = Prelude.Function.identity Text
              , Var = \(var : Project.Var) -> "\$" ++ var.rawName
              }
              queryFragment
        )

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        Compiled.ok
          Output
          { mkSqlExp = renderSqlExp input, docComment = renderDocComment input }

in  Algebra.Interpreter.module Input Output run
