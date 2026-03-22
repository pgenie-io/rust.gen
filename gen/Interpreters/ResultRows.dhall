let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Member = ./Member.dhall

let Input = Deps.Sdk.Project.ResultRows

let Output = Text -> { decoderBlock : Text, typeDecls : Text }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        let compiledColumns =
              Deps.Typeclasses.Classes.Applicative.traverseList
                Deps.Sdk.Compiled.Type
                Deps.Sdk.Compiled.applicative
                Deps.Sdk.Project.Member
                Member.Output
                (Member.run config)
                ( Deps.Prelude.NonEmpty.toList
                    Deps.Sdk.Project.Member
                    input.columns
                )

        in  Deps.Sdk.Compiled.flatMap
              (List Member.Output)
              Output
              ( \(columns : List Member.Output) ->
                  Deps.Sdk.Compiled.ok
                    Output
                    ( \(typeNameBase : Text) ->
                        let rowTypeName = "OutputRow"

                        let fieldDecls =
                              Deps.Prelude.Text.concatMapSep
                                "\n"
                                Member.Output
                                (\(col : Member.Output) -> col.fieldDeclaration)
                                columns

                        let decoderFields =
                              Deps.Prelude.Text.concatMapSep
                                ",\n"
                                Member.Output
                                ( \(col : Member.Output) ->
                                    "            ${col.fieldName}: ${col.decoderExpr}"
                                )
                                columns

                        let rowTypeDecl =
                              ''
                              /// Row of the output.
                              #[derive(Debug, Clone)]
                              pub struct ${rowTypeName} {
                              ${fieldDecls}
                              }

                              impl ${rowTypeName} {
                                  pub fn from_row(row: &tokio_postgres::Row) -> Self {
                                      Self {
                              ${decoderFields},
                                      }
                                  }
                              }
                              ''

                        let resolvedCardinality =
                              merge
                                { Optional =
                                  { decoderBlock = "optional"
                                  , resultTypeDecl =
                                      "/// Output type: at most one row.\npub type Output = Option<OutputRow>;"
                                  }
                                , Single =
                                  { decoderBlock = "single"
                                  , resultTypeDecl =
                                      "/// Output type: exactly one row.\npub type Output = OutputRow;"
                                  }
                                , Multiple =
                                  { decoderBlock = "multiple"
                                  , resultTypeDecl =
                                      "/// Output type: multiple rows.\npub type Output = Vec<OutputRow>;"
                                  }
                                }
                                input.cardinality

                        let typeDecls =
                              ''
                              ${resolvedCardinality.resultTypeDecl}

                              ${rowTypeDecl}
                              ''

                        in  { decoderBlock = resolvedCardinality.decoderBlock
                            , typeDecls
                            }
                    )
              )
              compiledColumns

in  Algebra.module Input Output run
