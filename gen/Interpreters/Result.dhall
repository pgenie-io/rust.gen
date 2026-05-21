let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Project = ../Deps/Project.dhall

let ResultRows = ./ResultRows.dhall

let Input = Project.Result

let ExtraCtx = { sqlExp : Text, paramTypes : Text, paramExprs : Text }

let Output = ExtraCtx -> Text -> { typeDecls : Text, statementImpl : Text }

let Result = Lude.Compiled.Type Output

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        Prelude.Optional.fold
          ResultRows.Input
          input
          Result
          (ResultRows.run config)
          ( Lude.Compiled.ok
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
                          type Result = Output;

                          const RETURNS_ROWS: bool = false;

                          const SQL: &str = ${Lude.Text.indentNonEmpty
                                                23
                                                ctx.sqlExp};

                          const PARAM_TYPES: &'static [tokio_postgres::types::Type] = &[${ctx.paramTypes}];

                          #[allow(refining_impl_trait)]
                          fn encode_params(
                              &self,
                          ) -> [&(dyn tokio_postgres::types::ToSql + Sync); Self::PARAM_TYPES.len()] {
                              [${ctx.paramExprs}]
                          }

                          fn decode_result(
                              _rows: Vec<tokio_postgres::Row>,
                              affected_rows: u64,
                          ) -> Result<Self::Result, crate::mapping::DecodingError> {
                              Ok(affected_rows)
                          }
                      }
                      ''
                  }
              )
          )

in  Algebra.Interpreter.module Input Output run
