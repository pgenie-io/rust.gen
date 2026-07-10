let Sdk = ../Deps/Sdk.dhall

let Params = {}

in  Sdk.Sigs.Template.module
      Params
      ( \(_ : Params) ->
          ''
          /// Result of the statement parameterised by [`Input`].
          ///
          /// Contains the number of rows affected by the statement.
          pub type Output = u64;
          ''
      )
