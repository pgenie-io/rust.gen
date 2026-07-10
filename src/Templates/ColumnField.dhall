let Sdk = ../Deps/Sdk.dhall

let Params = { pgName : Text, fieldName : Text, fieldType : Text }

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
          ''
          /// Maps to the `${params.pgName}` result set column.
          pub ${params.fieldName}: ${params.fieldType},''
      )
