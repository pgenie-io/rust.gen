let Sdk = ../Deps/Sdk.dhall

let Params = { alias : Text }

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
          ''
          /// Result of the statement parameterised by [`Input`].
          pub type Output = ${params.alias};
          ''
      )
