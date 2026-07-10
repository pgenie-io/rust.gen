let Sdk = ../Deps/Sdk.dhall

let Lude = ../Deps/Lude.dhall

let Params = { sqlExp : Text, paramTypes : Text, paramExprs : Text }

in  Sdk.Sigs.Template.module
      Params
      ( \(params : Params) ->
          ''
          impl crate::mapping::Statement for Input {
              type Result = Output;

              const RETURNS_ROWS: bool = false;

              const SQL: &str = ${Lude.Text.indentNonEmpty 23 params.sqlExp};

              const PARAM_TYPES: &'static [tokio_postgres::types::Type] = &[${params.paramTypes}];

              #[allow(refining_impl_trait)]
              fn encode_params(
                  &self,
              ) -> [&(dyn tokio_postgres::types::ToSql + Sync); Self::PARAM_TYPES.len()] {
                  [${params.paramExprs}]
              }

              fn decode_result(
                  _rows: Vec<tokio_postgres::Row>,
                  _affected_rows: u64,
              ) -> Result<Self::Result, crate::mapping::DecodingError> {
                  Ok(())
              }
          }
          ''
      )
