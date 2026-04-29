let Prelude = ../Deps/Prelude.dhall

let Variant = { name : Text, pgValue : Text }

let Params =
      { typeName : Text
      , pgSchema : Text
      , pgTypeName : Text
      , variants : List Variant
      }

let renderVariant =
      \(variant : Variant) ->
        ''
            /// Corresponds to the PostgreSQL enum variant `${variant.pgValue}`.
            #[postgres(name = "${variant.pgValue}")]
            ${variant.name},
        ''

let renderFirstVariant =
      \(variant : Variant) ->
        ''
            /// Corresponds to the PostgreSQL enum variant `${variant.pgValue}`.
            #[postgres(name = "${variant.pgValue}")]
            #[default]
            ${variant.name},
        ''

let run =
      \(params : Params) ->
        let variantDecls =
              merge
                { None = ""
                , Some =
                    \(head : Variant) ->
                      let first = renderFirstVariant head

                      let rest =
                            Prelude.Text.concatMap
                              Variant
                              renderVariant
                              (Prelude.List.drop 1 Variant params.variants)

                      in  first ++ rest
                }
                (List/head Variant params.variants)

        in  ''
            use postgres_types::{FromSql, ToSql};

            /// Representation of the `${params.pgTypeName}` user-declared PostgreSQL enumeration type.
            #[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, ToSql, FromSql)]
            #[postgres(name = "${params.pgTypeName}")]
            #[derive(Default)]
            pub enum ${params.typeName} {
            ${variantDecls}}
            ''

in  { Params, Variant, run }
