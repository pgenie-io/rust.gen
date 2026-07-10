let Sdk = ../Deps/Sdk.dhall

let Lude = ../Deps/Lude.dhall

let Params = { fields : Text }

in  Sdk.Sigs.Template.module
      Params
      ( \(params : Params) ->
          ''
          match rows.len() {
              0 => Ok(None),
              1 => {
                  let row = rows.first().unwrap();
                  Ok(Some(OutputRow {
                      ${Lude.Text.indentNonEmpty 20 params.fields}
                  }))
              }
              n => Err(crate::mapping::DecodingError::UnexpectedAmountOfRows {
                  expected: 1,
                  actual: n,
              }),
          }''
      )
