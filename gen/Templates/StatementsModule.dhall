let Algebra = ../Algebras/package.dhall

let Params = { stmtModNames : Text }

in  Algebra.Template.module
      Params
      ( \(params : Params) ->
          ''
          //! Mappings to all queries in the project.
          //!
          //! Each sub-module exposes a parameter struct that implements [`crate::mapping::Statement`].

          ${params.stmtModNames}
          ''
      )
