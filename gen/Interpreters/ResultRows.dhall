let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Member = ./Member.dhall

let Input = Deps.Sdk.Project.ResultRows

let ExtraCtx = { sqlExp : Text, paramTypes : Text, paramExprs : Text }

let Output = ExtraCtx -> Text -> { statementImpl : Text, typeDecls : Text }

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
                    ( \(ctx : ExtraCtx) ->
                      \(typeNameBase : Text) ->
                        let rowTypeName = "OutputRow"

                        let fieldDecls =
                              Deps.Prelude.Text.concatMapSep
                                "\n"
                                Member.Output
                                (\(col : Member.Output) -> col.columnFieldDeclaration)
                                columns

                        let indexedColumns =
                              Deps.Prelude.List.indexed Member.Output columns

                        let singleDecoderFields =
                              Deps.Prelude.Text.concatSep
                                "\n"
                                ( Deps.Prelude.List.map
                                    { index : Natural, value : Member.Output }
                                    Text
                                    ( \(ic : { index : Natural, value : Member.Output }) ->
                                            "                    "
                                        ++  ic.value.fieldName
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
                                    ( \(ic : { index : Natural, value : Member.Output }) ->
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
                                  "impl crate::mapping::Statement for Input {\n"
                              ++  "    type Result = Output;\n"
                              ++  "\n"
                              ++  "    const RETURNS_ROWS: bool = true;\n"
                              ++  "\n"
                              ++  "    const SQL: &str = "
                              ++  ctx.sqlExp
                              ++  ";\n"
                              ++  "\n"
                              ++  "    const PARAM_TYPES: &'static [tokio_postgres::types::Type] = &["
                              ++  ctx.paramTypes
                              ++  "];\n"
                              ++  "\n"
                              ++  "    #[allow(refining_impl_trait)]\n"
                              ++  "    fn encode_params(\n"
                              ++  "        &self,\n"
                              ++  "    ) -> [&(dyn tokio_postgres::types::ToSql + Sync); Self::PARAM_TYPES.len()] {\n"
                              ++  "        ["
                              ++  ctx.paramExprs
                              ++  "]\n"
                              ++  "    }\n"

                        let resolvedCardinality =
                              merge
                                { Optional =
                                  { statementImpl =
                                          implPreamble
                                      ++  "\n"
                                      ++  "    fn decode_result(\n"
                                      ++  "        rows: Vec<tokio_postgres::Row>,\n"
                                      ++  "        _affected_rows: u64,\n"
                                      ++  "    ) -> Result<Self::Result, crate::mapping::DecodingError> {\n"
                                      ++  "        match rows.len() {\n"
                                      ++  "            0 => Ok(None),\n"
                                      ++  "            1 => {\n"
                                      ++  "                let row = rows.first().unwrap();\n"
                                      ++  "                Ok(Some(OutputRow {\n"
                                      ++  singleDecoderFields
                                      ++  "\n"
                                      ++  "                }))\n"
                                      ++  "            }\n"
                                      ++  "            n => Err(crate::mapping::DecodingError::UnexpectedAmountOfRows {\n"
                                      ++  "                expected: 1,\n"
                                      ++  "                actual: n,\n"
                                      ++  "            }),\n"
                                      ++  "        }\n"
                                      ++  "    }\n"
                                      ++  "}"
                                  , resultTypeDecl =
                                      "/// Result of the statement parameterised by [`Input`].\npub type Output = Option<OutputRow>;"
                                  }
                                , Single =
                                  { statementImpl =
                                          implPreamble
                                      ++  "\n"
                                      ++  "    fn decode_result(\n"
                                      ++  "        rows: Vec<tokio_postgres::Row>,\n"
                                      ++  "        _affected_rows: u64,\n"
                                      ++  "    ) -> Result<Self::Result, crate::mapping::DecodingError> {\n"
                                      ++  "        match rows.len() {\n"
                                      ++  "            0 => Err(crate::mapping::DecodingError::UnexpectedAmountOfRows {\n"
                                      ++  "                expected: 1,\n"
                                      ++  "                actual: 0,\n"
                                      ++  "            }),\n"
                                      ++  "            1 => {\n"
                                      ++  "                let row = rows.first().unwrap();\n"
                                      ++  "                Ok(OutputRow {\n"
                                      ++  singleDecoderFields
                                      ++  "\n"
                                      ++  "                })\n"
                                      ++  "            }\n"
                                      ++  "            n => Err(crate::mapping::DecodingError::UnexpectedAmountOfRows {\n"
                                      ++  "                expected: 1,\n"
                                      ++  "                actual: n,\n"
                                      ++  "            }),\n"
                                      ++  "        }\n"
                                      ++  "    }\n"
                                      ++  "}"
                                  , resultTypeDecl =
                                      "/// Result of the statement parameterised by [`Input`].\npub type Output = OutputRow;"
                                  }
                                , Multiple =
                                  { statementImpl =
                                          implPreamble
                                      ++  "\n"
                                      ++  "    fn decode_result(\n"
                                      ++  "        rows: Vec<tokio_postgres::Row>,\n"
                                      ++  "        _affected_rows: u64,\n"
                                      ++  "    ) -> Result<Self::Result, crate::mapping::DecodingError> {\n"
                                      ++  "        rows.into_iter()\n"
                                      ++  "            .enumerate()\n"
                                      ++  "            .map(|(row_index, row)| {\n"
                                      ++  "                Ok(OutputRow {\n"
                                      ++  multipleDecoderFields
                                      ++  "\n"
                                      ++  "                })\n"
                                      ++  "            })\n"
                                      ++  "            .collect()\n"
                                      ++  "    }\n"
                                      ++  "}"
                                  , resultTypeDecl =
                                      "/// Result of the statement parameterised by [`Input`].\npub type Output = Vec<OutputRow>;"
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
