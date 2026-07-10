let Sdk = ../Deps/Sdk.dhall

let Lude = ../Deps/Lude.dhall

let Params = { fields : Text }

in  Sdk.Sigs.Template.module
      Params
      ( \(params : Params) ->
          ''
          /// Row of [`Output`].
          #[derive(Debug, Clone, PartialEq)]
          pub struct OutputRow {
              ${Lude.Text.indentNonEmpty 4 params.fields}
          }''
      )
