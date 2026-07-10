let Sdk = ../Deps/Sdk.dhall

let Params = {}

in  Sdk.Sigs.template
      Params
      ( \(_ : Params) ->
          ''
          /// Result of the statement parameterised by [`Input`].
          ///
          /// Contains no value.
          pub type Output = ();
          ''
      )
