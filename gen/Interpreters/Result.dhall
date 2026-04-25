let Deps = ../Deps/package.dhall

let Algebra = ../Algebras/package.dhall

let ResultRows = ./ResultRows.dhall

let Input = Deps.Sdk.Project.Result

let ExtraCtx = { sqlExp : Text, paramTypes : Text, paramExprs : Text }

let Output = ExtraCtx -> Text -> { typeDecls : Text, statementImpl : Text }

let Result = Deps.Sdk.Compiled.Type Output

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        Deps.Prelude.Optional.fold
          ResultRows.Input
          input
          Result
          (ResultRows.run config)
          ( Deps.Sdk.Compiled.ok
              Output
              ( \(ctx : ExtraCtx) ->
                \(typeNameBase : Text) ->
                  { typeDecls =
                      ''
                      /// Result of the statement parameterised by [`Input`].
                      ///
                      /// Contains the number of rows affected by the statement.
                      pub type Output = u64;
                      ''
                  , statementImpl =
                          ''
                          impl crate::mapping::Statement for Input {
                          ''
                      ++  ''
                              type Result = Output;
                          ''
                      ++  "\n"
                      ++  ''
                              const RETURNS_ROWS: bool = false;
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
                      ++  "\n"
                      ++  ''
                              fn decode_result(
                          ''
                      ++  ''
                                  _rows: Vec<tokio_postgres::Row>,
                          ''
                      ++  ''
                                  affected_rows: u64,
                          ''
                      ++  ''
                              ) -> Result<Self::Result, crate::mapping::DecodingError> {
                          ''
                      ++  ''
                                  Ok(affected_rows)
                          ''
                      ++  ''
                              }
                          ''
                      ++  "}"
                  }
              )
          )

in  Algebra.Interpreter.module Input Output run
