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
          { Bit = ok "bit_vec::BitVec" "bit"
          , Bool = ok "bool" "bool"
          , Box = ok "geo_types::Rect<f64>" "box"
          , Bpchar = ok "String" "bpchar"
          , Bytea = ok "Vec<u8>" "bytea"
          , Char = ok "i8" "char"
          , Cidr = unsupportedType "cidr"
          , Circle = unsupportedType "circle"
          , Citext = ok "String" "citext"
          , Date = ok "chrono::NaiveDate" "date"
          , Datemultirange = unsupportedType "datemultirange"
          , Daterange = unsupportedType "daterange"
          , Float4 = ok "f32" "float4"
          , Float8 = ok "f64" "float8"
          , Hstore = ok "std::collections::HashMap<String, Option<String>>" "hstore"
          , Inet = ok "std::net::IpAddr" "inet"
          , Int2 = ok "i16" "int2"
          , Int4 = ok "i32" "int4"
          , Int4multirange = unsupportedType "int4multirange"
          , Int4range = unsupportedType "int4range"
          , Int8 = ok "i64" "int8"
          , Int8multirange = unsupportedType "int8multirange"
          , Int8range = unsupportedType "int8range"
          , Interval = unsupportedType "interval"
          , Json = ok "serde_json::Value" "json"
          , Jsonb = ok "serde_json::Value" "jsonb"
          , Line = unsupportedType "line"
          , Lseg = unsupportedType "lseg"
          , Macaddr = ok "eui48::MacAddress" "macaddr"
          , Macaddr8 = unsupportedType "macaddr8"
          , Money = unsupportedType "money"
          , Name = ok "String" "name"
          , Numeric = ok "rust_decimal::Decimal" "numeric"
          , Nummultirange = unsupportedType "nummultirange"
          , Numrange = unsupportedType "numrange"
          , Oid = ok "u32" "oid"
          , Path = ok "geo_types::LineString<f64>" "path"
          , PgLsn = unsupportedType "pg_lsn"
          , PgSnapshot = unsupportedType "pg_snapshot"
          , Point = ok "geo_types::Point<f64>" "point"
          , Polygon = unsupportedType "polygon"
          , Text = ok "String" "text"
          , Time = ok "chrono::NaiveTime" "time"
          , Timestamp = ok "chrono::NaiveDateTime" "timestamp"
          , Timestamptz = ok "chrono::DateTime<chrono::Utc>" "timestamptz"
          , Timetz = unsupportedType "timetz"
          , Tsmultirange = unsupportedType "tsmultirange"
          , Tsquery = unsupportedType "tsquery"
          , Tsrange = unsupportedType "tsrange"
          , Tstzmultirange = unsupportedType "tstzmultirange"
          , Tstzrange = unsupportedType "tstzrange"
          , Tsvector = unsupportedType "tsvector"
          , Uuid = ok "uuid::Uuid" "uuid"
          , Varbit = ok "bit_vec::BitVec" "varbit"
          , Varchar = ok "String" "varchar"
          , Xml = unsupportedType "xml"
          }
          input

in  Algebra.module Input Output run
