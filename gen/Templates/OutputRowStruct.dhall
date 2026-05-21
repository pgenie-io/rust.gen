let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Params = { fields : Text }

in  Algebra.Template.module
      Params
      ( \(params : Params) ->
          ''
          /// Row of [`Output`].
          #[derive(Debug, Clone, PartialEq)]
          pub struct OutputRow {
              ${Lude.Text.indentNonEmpty 4 params.fields}
          }''
      )
