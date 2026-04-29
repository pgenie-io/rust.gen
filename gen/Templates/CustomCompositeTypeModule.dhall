let Prelude = ../Deps/Prelude.dhall

let Field = { pgName : Text, fieldName : Text, fieldType : Text }

let Params =
      { typeName : Text
      , pgSchema : Text
      , pgTypeName : Text
      , fields : List Field
      }

let run =
      \(params : Params) ->
        let fieldDecls =
              Prelude.Text.concatMap
                Field
                ( \(field : Field) ->
                    ''
                        /// Maps to `${field.pgName}`.
                        #[postgres(name = "${field.pgName}")]
                        pub ${field.fieldName}: ${field.fieldType},
                    ''
                )
                params.fields

        in  ''
            use postgres_types::{ToSql, FromSql};

            /// Representation of the `${params.pgTypeName}` PostgreSQL composite type.
            #[derive(Debug, Clone, PartialEq, Eq, Default, ToSql, FromSql)]
            #[postgres(name = "${params.pgTypeName}")]
            pub struct ${params.typeName} {
            ${fieldDecls}}
            ''

in  { Params, Field, run }
