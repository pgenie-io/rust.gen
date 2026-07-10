let Sdk = ../Deps/Sdk.dhall

let Params = { typeModNames : Text, typeReexports : Text }

in  Sdk.Sigs.Template.module
      Params
      ( \(params : Params) ->
          ''
          ${params.typeModNames}
          ${params.typeReexports}
          ''
      )
