let Lude = ../Deps/Lude.dhall

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
              Prelude.Text.concatMapSep
                "\n"
                Field
                ( \(field : Field) ->
                    ''
                    /// Maps to `${field.pgName}`.
                    #[postgres(name = "${field.pgName}")]
                    pub ${field.fieldName}: ${field.fieldType},''
                )
                params.fields

        in  ''
            use postgres_types::{ToSql, FromSql};

            /// Representation of the `${params.pgTypeName}` PostgreSQL composite type.
            #[derive(Debug, Clone, PartialEq, Default, ToSql, FromSql)]
            #[postgres(name = "${params.pgTypeName}")]
            pub struct ${params.typeName} {
                ${Lude.Text.indentNonEmpty 4 fieldDecls}
            }
            ''

in  { Params, Field, run }
