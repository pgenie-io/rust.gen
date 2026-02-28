let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Input = Deps.Sdk.Project.Primitive

let Output = { sig : Text, codecName : Text }

let unsupportedType =
      \(type : Text) ->
        Deps.Sdk.Compiled.report Output [ type ] "Unsupported type"

let ok =
      \(sig : Text) ->
      \(codecName : Text) ->
        Deps.Sdk.Compiled.ok Output { sig, codecName }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        merge
          { Bool = ok "bool" "bool"
          , Bytea = ok "Vec<u8>" "bytea"
          , Char = ok "i8" "char"
          , Cidr = unsupportedType "cidr"
          , Date = ok "chrono::NaiveDate" "date"
          , Datemultirange = unsupportedType "datemultirange"
          , Daterange = unsupportedType "daterange"
          , Float4 = ok "f32" "float4"
          , Float8 = ok "f64" "float8"
          , Inet = unsupportedType "inet"
          , Int2 = ok "i16" "int2"
          , Int4 = ok "i32" "int4"
          , Int4multirange = unsupportedType "int4multirange"
          , Int4range = unsupportedType "int4range"
          , Int8 = ok "i64" "int8"
          , Int8multirange = unsupportedType "int8multirange"
          , Int8range = unsupportedType "int8range"
          , Interval = unsupportedType "interval"
          , Json = unsupportedType "json"
          , Jsonb = ok "serde_json::Value" "jsonb"
          , Macaddr = unsupportedType "macaddr"
          , Macaddr8 = unsupportedType "macaddr8"
          , Money = unsupportedType "money"
          , Numeric = ok "rust_decimal::Decimal" "numeric"
          , Nummultirange = unsupportedType "nummultirange"
          , Numrange = unsupportedType "numrange"
          , Text = ok "String" "text"
          , Time = ok "chrono::NaiveTime" "time"
          , Timestamp = ok "chrono::NaiveDateTime" "timestamp"
          , Timestamptz = ok "chrono::DateTime<chrono::Utc>" "timestamptz"
          , Timetz = unsupportedType "timetz"
          , Tsmultirange = unsupportedType "tsmultirange"
          , Tsrange = unsupportedType "tsrange"
          , Tstzmultirange = unsupportedType "tstzmultirange"
          , Tstzrange = unsupportedType "tstzrange"
          , Uuid = ok "uuid::Uuid" "uuid"
          , Xml = unsupportedType "xml"
          }
          input

in  Algebra.module Input Output run
