let Sdk = ../Deps/Sdk.dhall

let Params = { stmtModNames : Text }

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
          ''
          //! Mappings to all queries in the project.
          //!
          //! Each sub-module exposes a parameter struct that implements [`crate::mapping::Statement`].

          ${params.stmtModNames}
          ''
      )
