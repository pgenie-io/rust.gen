let Sdk = ../Deps/Sdk.dhall

let Lude = ../Deps/Lude.dhall

let Params = { fields : Text }

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
          ''
          match rows.len() {
              0 => Err(crate::mapping::DecodingError::UnexpectedAmountOfRows {
                  expected: 1,
                  actual: 0,
              }),
              1 => {
                  let row = rows.first().unwrap();
                  Ok(OutputRow {
                      ${Lude.Text.indentNonEmpty 20 params.fields}
                  })
              }
              n => Err(crate::mapping::DecodingError::UnexpectedAmountOfRows {
                  expected: 1,
                  actual: n,
              }),
          }''
      )
