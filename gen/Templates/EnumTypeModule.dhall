let Deps = ../Deps/package.dhall

let Variant = { name : Text, pgValue : Text }

let Input =
      { typeName : Text
      , pgSchema : Text
      , pgTypeName : Text
      , variants : List Variant
      }

let run =
      \(input : Input) ->
        ''
        //! Representation of the `${input.pgTypeName}` PostgreSQL enumeration type.

        use postgres_types::{FromSql, ToSql};

        /// Representation of the `${input.pgTypeName}` user-declared PostgreSQL enumeration type
        /// from the `${input.pgSchema}` schema.
        #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, ToSql, FromSql)]
        #[postgres(name = "${input.pgTypeName}")]
        pub enum ${input.typeName} {
        ${Deps.Prelude.Text.concatMap
            Variant
            ( \(variant : Variant) ->
                ''
                    /// Corresponds to the PostgreSQL enum variant `${variant.pgValue}`.
                    #[postgres(name = "${variant.pgValue}")]
                    ${variant.name},
                ''
            )
            input.variants}}
        ''

in  { Input, Variant, run }
