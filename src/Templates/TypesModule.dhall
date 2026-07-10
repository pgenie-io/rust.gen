let Sdk = ../Deps/Sdk.dhall

let Params = { typeModNames : Text, typeReexports : Text }

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
          ''
          ${params.typeModNames}
          ${params.typeReexports}
          ''
      )
