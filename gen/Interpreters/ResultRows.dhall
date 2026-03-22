let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Member = ./Member.dhall

let Input = Deps.Sdk.Project.ResultRows

let Output = Text -> { statementImpl : Text, typeDecls : Text }

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
                                  { statementImpl =
                                      ''
                                      impl crate::Statement for Input {
                                          type Output = Output;

                                          fn sql() -> &'static str {
                                              SQL
                                          }

                                          fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
                                              self.params()
                                          }

                                          fn decode(rows: Vec<tokio_postgres::Row>, _rows_affected: u64) -> Self::Output {
                                              rows.into_iter().next().map(|row| OutputRow::from_row(&row))
                                          }
                                      }
                                      ''
                                  , resultTypeDecl =
                                      "/// Output type: at most one row.\npub type Output = Option<OutputRow>;"
                                  }
                                , Single =
                                  { statementImpl =
                                      ''
                                      impl crate::Statement for Input {
                                          type Output = Output;

                                          fn sql() -> &'static str {
                                              SQL
                                          }

                                          fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
                                              self.params()
                                          }

                                          fn decode(rows: Vec<tokio_postgres::Row>, _rows_affected: u64) -> Self::Output {
                                              let row = rows.into_iter().next().expect("expected exactly one row");
                                              OutputRow::from_row(&row)
                                          }
                                      }
                                      ''
                                  , resultTypeDecl =
                                      "/// Output type: exactly one row.\npub type Output = OutputRow;"
                                  }
                                , Multiple =
                                  { statementImpl =
                                      ''
                                      impl crate::Statement for Input {
                                          type Output = Output;

                                          fn sql() -> &'static str {
                                              SQL
                                          }

                                          fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
                                              self.params()
                                          }

                                          fn decode(rows: Vec<tokio_postgres::Row>, _rows_affected: u64) -> Self::Output {
                                              rows.iter().map(|row| OutputRow::from_row(row)).collect()
                                          }
                                      }
                                      ''
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

                        in  { statementImpl = resolvedCardinality.statementImpl
                            , typeDecls
                            }
                    )
              )
              compiledColumns

in  Algebra.module Input Output run
