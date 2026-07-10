let Sdk = ../Deps/Sdk.dhall

let Params = { pgName : Text, fieldName : Text, fieldType : Text }

in  Sdk.Sigs.Template.module
      Params
      ( \(params : Params) ->
          ''
          /// Maps to `$${params.pgName}` in the template.
          pub ${params.fieldName}: ${params.fieldType},''
      )
