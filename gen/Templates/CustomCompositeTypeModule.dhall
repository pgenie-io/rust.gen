let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let Params =
      { typeName : Text
      , pgSchema : Text
      , pgTypeName : Text
      , fieldDeclarations : List Text
      }

let run =
      \(params : Params) ->
        let fieldDecls =
              Deps.Prelude.Text.concatMapSep
                "\n"
                Text
                ( \(field : Text) ->
                    "    ${field},"
                )
                params.fieldDeclarations

        in  ''
            use postgres_types::{ToSql, FromSql};

            /// Representation of the `${params.pgTypeName}` PostgreSQL composite type.
            #[derive(Debug, Clone, PartialEq, ToSql, FromSql)]
            #[postgres(name = "${params.pgTypeName}")]
            pub struct ${params.typeName} {
            ${fieldDecls}
            }
            ''

in  Algebra.module Params run
