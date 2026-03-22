let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let Variant = { name : Text, pgValue : Text }

let Params =
      { typeName : Text
      , pgSchema : Text
      , pgTypeName : Text
      , variants : List Variant
      }

let run =
      \(params : Params) ->
        let variantDecls =
              Deps.Prelude.Text.concatMapSep
                "\n"
                Variant
                ( \(variant : Variant) ->
                    ''
                        /// Corresponds to the PostgreSQL enum variant `${variant.pgValue}`.
                        #[postgres(name = "${variant.pgValue}")]
                        ${variant.name},''
                )
                params.variants

        in  ''
            use postgres_types::{ToSql, FromSql};

            /// Representation of the `${params.pgTypeName}` PostgreSQL enumeration type.
            #[derive(Debug, Clone, PartialEq, Eq, ToSql, FromSql)]
            #[postgres(name = "${params.pgTypeName}")]
            pub enum ${params.typeName} {
            ${variantDecls}
            }
            ''

in  { Params, Variant, run }
