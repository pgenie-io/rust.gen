let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let ResultRows = ./ResultRows.dhall

let Input = Deps.Sdk.Project.Result

let ExtraCtx = { sqlExp : Text, paramTypes : Text, paramExprs : Text }

let Output = ExtraCtx -> Text -> { typeDecls : Text, statementImpl : Text }

let Result = Deps.Sdk.Compiled.Type Output

let run =
      \(config : Algebra.Config) ->
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
                          "impl crate::mapping::Statement for Input {\n"
                      ++  "    type Result = Output;\n"
                      ++  "\n"
                      ++  "    const RETURNS_ROWS: bool = false;\n"
                      ++  "\n"
                      ++  "    const SQL: &str = "
                      ++  Deps.Lude.Extensions.Text.indent 23 ctx.sqlExp
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
                      ++  "\n"
                      ++  "    fn decode_result(\n"
                      ++  "        _rows: Vec<tokio_postgres::Row>,\n"
                      ++  "        affected_rows: u64,\n"
                      ++  "    ) -> Result<Self::Result, crate::mapping::DecodingError> {\n"
                      ++  "        Ok(affected_rows)\n"
                      ++  "    }\n"
                      ++  "}"
                  }
              )
          )

in  Algebra.module Input Output run
