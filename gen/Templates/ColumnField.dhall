let Algebra = ../Algebras/package.dhall

let Params = { pgName : Text, fieldName : Text, fieldType : Text }

in  Algebra.Template.module
      Params
      ( \(params : Params) ->
          ''
          /// Maps to the `${params.pgName}` result set column.
          pub ${params.fieldName}: ${params.fieldType},''
      )
