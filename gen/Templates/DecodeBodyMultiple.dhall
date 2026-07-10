let Sdk = ../Deps/Sdk.dhall

let Lude = ../Deps/Lude.dhall

let Params = { fields : Text }

in  Sdk.Sigs.Template.module
      Params
      ( \(params : Params) ->
          ''
          rows.into_iter()
              .enumerate()
              .map(|(row_index, row)| {
                  Ok(OutputRow {
                      ${Lude.Text.indentNonEmpty 20 params.fields}
                  })
              })
              .collect()''
      )
