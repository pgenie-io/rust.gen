let Algebra = ../Algebras/package.dhall

let Params = { pgName : Text, fieldName : Text, fieldType : Text }

in  Algebra.Template.module
      Params
      ( \(params : Params) ->
          ''
          /// Maps to `$${params.pgName}` in the template.
          pub ${params.fieldName}: ${params.fieldType},''
      )
