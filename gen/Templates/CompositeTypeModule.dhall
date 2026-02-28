let Deps = ../Deps/package.dhall

let Input =
      { typeName : Text
      , pgSchema : Text
      , pgTypeName : Text
      , fieldDeclarations : List Text
      }

let run =
      \(input : Input) ->
        ''
        //! Representation of the `${input.pgTypeName}` PostgreSQL composite type.

        use postgres_types::{FromSql, ToSql};

        /// Representation of the `${input.pgTypeName}` user-declared PostgreSQL composite type
        /// from the `${input.pgSchema}` schema.
        #[derive(Debug, Clone, PartialEq, FromSql, ToSql)]
        #[postgres(name = "${input.pgTypeName}")]
        pub struct ${input.typeName} {
        ${Deps.Prelude.Text.concatMap
            Text
            (\(field : Text) -> field ++ "\n")
            input.fieldDeclarations}}
        ''

in  { Input, run }
