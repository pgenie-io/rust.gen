let Algebra = ../Algebras/package.dhall

let Params = { rootModuleName : Text }

in  Algebra.Template.module
      Params
      ( \(params : Params) ->
          ''
          //! Type-safe bindings for the `${params.rootModuleName}` database.
          //!
          //! Generated from SQL queries using the [pGenie](https://pgenie.io) code generator.
          //!
          //! - [`statements`] – ready-to-use statement definitions for all queries with
          //!   associated parameter and result types.
          //! - [`mapping`] – shared PostgreSQL statement mapping primitives used by the
          //!   generated statements and tests.
          //! - [`types`] – PostgreSQL enum and composite type mappings.

          pub mod mapping;
          pub mod statements;
          pub mod types;
          ''
      )
