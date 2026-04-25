let Deps = ../Deps/package.dhall

let Algebra = ../Algebras/package.dhall

let Member = ./Member.dhall

let Input = Deps.Sdk.Project.ResultRows

let ExtraCtx = { sqlExp : Text, paramTypes : Text, paramExprs : Text }

let Output = ExtraCtx -> Text -> { statementImpl : Text, typeDecls : Text }

let run =
      \(config : Algebra.Interpreter.Config) ->
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
                    ( \(ctx : ExtraCtx) ->
                      \(typeNameBase : Text) ->
                        let rowTypeName = "OutputRow"

                        let fieldDecls =
                              Deps.Prelude.Text.concatMapSep
                                "\n"
                                Member.Output
                                ( \(col : Member.Output) ->
                                    col.columnFieldDeclaration
                                )
                                columns

                        let indexedColumns =
                              Deps.Prelude.List.indexed Member.Output columns

                        let singleDecoderFields =
                              Deps.Prelude.Text.concatSep
                                "\n"
                                ( Deps.Prelude.List.map
                                    { index : Natural, value : Member.Output }
                                    Text
                                    ( \ ( ic
                                        : { index : Natural
                                          , value : Member.Output
                                          }
                                        ) ->
                                            "                    "
                                        ++  ic.value.rustFieldName
                                        ++  ": crate::mapping::decode_cell(row, 0, "
                                        ++  Natural/show ic.index
                                        ++  ")?,"
                                    )
                                    indexedColumns
                                )

                        let multipleDecoderFields =
                              Deps.Prelude.Text.concatSep
                                "\n"
                                ( Deps.Prelude.List.map
                                    { index : Natural, value : Member.Output }
                                    Text
                                    ( \ ( ic
                                        : { index : Natural
                                          , value : Member.Output
                                          }
                                        ) ->
                                            "                    "
                                        ++  ic.value.rustFieldName
                                        ++  ": crate::mapping::decode_cell(&row, row_index, "
                                        ++  Natural/show ic.index
                                        ++  ")?,"
                                    )
                                    indexedColumns
                                )

                        let rowTypeDecl =
                              ''
                              /// Row of [`Output`].
                              #[derive(Debug, Clone, PartialEq)]
                              pub struct ${rowTypeName} {
                              ${fieldDecls}
                              }
                              ''

                        let implPreamble =
                                  ''
                                  impl crate::mapping::Statement for Input {
                                  ''
                              ++  ''
                                      type Result = Output;
                                  ''
                              ++  "\n"
                              ++  ''
                                      const RETURNS_ROWS: bool = true;
                                  ''
                              ++  "\n"
                              ++  "    const SQL: &str = "
                              ++  Deps.Lude.Extensions.Text.indent 23 ctx.sqlExp
                              ++  ''
                                  ;
                                  ''
                              ++  "\n"
                              ++  "    const PARAM_TYPES: &'static [tokio_postgres::types::Type] = &["
                              ++  ctx.paramTypes
                              ++  ''
                                  ];
                                  ''
                              ++  "\n"
                              ++  ''
                                      #[allow(refining_impl_trait)]
                                  ''
                              ++  ''
                                      fn encode_params(
                                  ''
                              ++  ''
                                          &self,
                                  ''
                              ++  ''
                                      ) -> [&(dyn tokio_postgres::types::ToSql + Sync); Self::PARAM_TYPES.len()] {
                                  ''
                              ++  "        ["
                              ++  ctx.paramExprs
                              ++  ''
                                  ]
                                  ''
                              ++  ''
                                      }
                                  ''

                        let resolvedCardinality =
                              merge
                                { Optional =
                                  { statementImpl =
                                          implPreamble
                                      ++  "\n"
                                      ++  ''
                                              fn decode_result(
                                          ''
                                      ++  ''
                                                  rows: Vec<tokio_postgres::Row>,
                                          ''
                                      ++  ''
                                                  _affected_rows: u64,
                                          ''
                                      ++  ''
                                              ) -> Result<Self::Result, crate::mapping::DecodingError> {
                                          ''
                                      ++  ''
                                                  match rows.len() {
                                          ''
                                      ++  ''
                                                      0 => Ok(None),
                                          ''
                                      ++  ''
                                                      1 => {
                                          ''
                                      ++  ''
                                                          let row = rows.first().unwrap();
                                          ''
                                      ++  ''
                                                          Ok(Some(OutputRow {
                                          ''
                                      ++  singleDecoderFields
                                      ++  "\n"
                                      ++  ''
                                                          }))
                                          ''
                                      ++  ''
                                                      }
                                          ''
                                      ++  ''
                                                      n => Err(crate::mapping::DecodingError::UnexpectedAmountOfRows {
                                          ''
                                      ++  ''
                                                          expected: 1,
                                          ''
                                      ++  ''
                                                          actual: n,
                                          ''
                                      ++  ''
                                                      }),
                                          ''
                                      ++  ''
                                                  }
                                          ''
                                      ++  ''
                                              }
                                          ''
                                      ++  "}"
                                  , resultTypeDecl =
                                      ''
                                      /// Result of the statement parameterised by [`Input`].
                                      pub type Output = Option<OutputRow>;''
                                  }
                                , Single =
                                  { statementImpl =
                                          implPreamble
                                      ++  "\n"
                                      ++  ''
                                              fn decode_result(
                                          ''
                                      ++  ''
                                                  rows: Vec<tokio_postgres::Row>,
                                          ''
                                      ++  ''
                                                  _affected_rows: u64,
                                          ''
                                      ++  ''
                                              ) -> Result<Self::Result, crate::mapping::DecodingError> {
                                          ''
                                      ++  ''
                                                  match rows.len() {
                                          ''
                                      ++  ''
                                                      0 => Err(crate::mapping::DecodingError::UnexpectedAmountOfRows {
                                          ''
                                      ++  ''
                                                          expected: 1,
                                          ''
                                      ++  ''
                                                          actual: 0,
                                          ''
                                      ++  ''
                                                      }),
                                          ''
                                      ++  ''
                                                      1 => {
                                          ''
                                      ++  ''
                                                          let row = rows.first().unwrap();
                                          ''
                                      ++  ''
                                                          Ok(OutputRow {
                                          ''
                                      ++  singleDecoderFields
                                      ++  "\n"
                                      ++  ''
                                                          })
                                          ''
                                      ++  ''
                                                      }
                                          ''
                                      ++  ''
                                                      n => Err(crate::mapping::DecodingError::UnexpectedAmountOfRows {
                                          ''
                                      ++  ''
                                                          expected: 1,
                                          ''
                                      ++  ''
                                                          actual: n,
                                          ''
                                      ++  ''
                                                      }),
                                          ''
                                      ++  ''
                                                  }
                                          ''
                                      ++  ''
                                              }
                                          ''
                                      ++  "}"
                                  , resultTypeDecl =
                                      ''
                                      /// Result of the statement parameterised by [`Input`].
                                      pub type Output = OutputRow;''
                                  }
                                , Multiple =
                                  { statementImpl =
                                          implPreamble
                                      ++  "\n"
                                      ++  ''
                                              fn decode_result(
                                          ''
                                      ++  ''
                                                  rows: Vec<tokio_postgres::Row>,
                                          ''
                                      ++  ''
                                                  _affected_rows: u64,
                                          ''
                                      ++  ''
                                              ) -> Result<Self::Result, crate::mapping::DecodingError> {
                                          ''
                                      ++  ''
                                                  rows.into_iter()
                                          ''
                                      ++  ''
                                                      .enumerate()
                                          ''
                                      ++  ''
                                                      .map(|(row_index, row)| {
                                          ''
                                      ++  ''
                                                          Ok(OutputRow {
                                          ''
                                      ++  multipleDecoderFields
                                      ++  "\n"
                                      ++  ''
                                                          })
                                          ''
                                      ++  ''
                                                      })
                                          ''
                                      ++  ''
                                                      .collect()
                                          ''
                                      ++  ''
                                              }
                                          ''
                                      ++  "}"
                                  , resultTypeDecl =
                                      ''
                                      /// Result of the statement parameterised by [`Input`].
                                      pub type Output = Vec<OutputRow>;''
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

in  Algebra.Interpreter.module Input Output run
