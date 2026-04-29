let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Typeclasses = ../Deps/Typeclasses.dhall

let Project = ../Deps/Project.dhall

let Member = ./ResultColumnsMember.dhall

let Input = Project.ResultRows

let ExtraCtx = { sqlExp : Text, paramTypes : Text, paramExprs : Text }

let Output = ExtraCtx -> Text -> { statementImpl : Text, typeDecls : Text }

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        let compiledColumns =
              Typeclasses.Classes.Applicative.traverseList
                Lude.Compiled.Type
                Lude.Compiled.applicative
                Project.Member
                Member.Output
                (Member.run config)
                (Prelude.NonEmpty.toList Project.Member input.columns)

        in  Lude.Compiled.flatMap
              (List Member.Output)
              Output
              ( \(columns : List Member.Output) ->
                  Lude.Compiled.ok
                    Output
                    ( \(ctx : ExtraCtx) ->
                      \(typeNameBase : Text) ->
                        let rowTypeName = "OutputRow"

                        let fieldDecls =
                              Prelude.Text.concatMapSep
                                "\n"
                                Member.Output
                                ( \(col : Member.Output) ->
                                    col.columnFieldDeclaration
                                )
                                columns

                        let indexedColumns =
                              Prelude.List.indexed Member.Output columns

                        let singleDecoderFields =
                              Prelude.Text.concatSep
                                "\n"
                                ( Prelude.List.map
                                    { index : Natural, value : Member.Output }
                                    Text
                                    ( \ ( ic
                                        : { index : Natural
                                          , value : Member.Output
                                          }
                                        ) ->
                                            "                    "
                                        ++  ic.value.fieldName
                                        ++  ": crate::mapping::decode_cell(row, 0, "
                                        ++  Natural/show ic.index
                                        ++  ")?,"
                                    )
                                    indexedColumns
                                )

                        let multipleDecoderFields =
                              Prelude.Text.concatSep
                                "\n"
                                ( Prelude.List.map
                                    { index : Natural, value : Member.Output }
                                    Text
                                    ( \ ( ic
                                        : { index : Natural
                                          , value : Member.Output
                                          }
                                        ) ->
                                            "                    "
                                        ++  ic.value.fieldName
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
                              ++  Lude.Text.indent 23 ctx.sqlExp
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
