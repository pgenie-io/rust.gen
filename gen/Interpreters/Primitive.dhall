let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Input = Deps.Sdk.Project.Primitive

let Output = { sig : Text }

let unsupportedType =
      \(type : Text) ->
        Deps.Sdk.Compiled.report Output [ type ] "Unsupported type"

let std =
      \(sig : Text) ->
        Deps.Sdk.Compiled.ok Output { sig }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        merge
          { Bit = std "bit_vec::BitVec"
          , Bool = std "bool"
          , Box = std "geo_types::Rect<f64>"
          , Bpchar = std "String"
          , Bytea = std "Vec<u8>"
          , Char = std "i8"
          , Cidr = unsupportedType "cidr"
          , Circle = unsupportedType "circle"
          , Citext = std "String"
          , Date = std "chrono::NaiveDate"
          , Datemultirange = unsupportedType "datemultirange"
          , Daterange = unsupportedType "daterange"
          , Float4 = std "f32"
          , Float8 = std "f64"
          , Hstore = std "std::collections::HashMap<String, Option<String>>"
          , Inet = std "std::net::IpAddr"
          , Int2 = std "i16"
          , Int4 = std "i32"
          , Int4multirange = unsupportedType "int4multirange"
          , Int4range = unsupportedType "int4range"
          , Int8 = std "i64"
          , Int8multirange = unsupportedType "int8multirange"
          , Int8range = unsupportedType "int8range"
          , Interval = unsupportedType "interval"
          , Json = std "serde_json::Value"
          , Jsonb = std "serde_json::Value"
          , Line = unsupportedType "line"
          , Lseg = unsupportedType "lseg"
          , Macaddr = std "eui48::MacAddress"
          , Macaddr8 = unsupportedType "macaddr8"
          , Money = unsupportedType "money"
          , Name = std "String"
          , Numeric = std "rust_decimal::Decimal"
          , Nummultirange = unsupportedType "nummultirange"
          , Numrange = unsupportedType "numrange"
          , Oid = std "u32"
          , Path = std "geo_types::LineString<f64>"
          , PgLsn = unsupportedType "pg_lsn"
          , PgSnapshot = unsupportedType "pg_snapshot"
          , Point = std "geo_types::Point<f64>"
          , Polygon = unsupportedType "polygon"
          , Text = std "String"
          , Time = std "chrono::NaiveTime"
          , Timestamp = std "chrono::NaiveDateTime"
          , Timestamptz = std "chrono::DateTime<chrono::Utc>"
          , Timetz = unsupportedType "timetz"
          , Tsmultirange = unsupportedType "tsmultirange"
          , Tsquery = unsupportedType "tsquery"
          , Tsrange = unsupportedType "tsrange"
          , Tstzmultirange = unsupportedType "tstzmultirange"
          , Tstzrange = unsupportedType "tstzrange"
          , Tsvector = unsupportedType "tsvector"
          , Uuid = std "uuid::Uuid"
          , Varbit = std "bit_vec::BitVec"
          , Varchar = std "String"
          , Xml = unsupportedType "xml"
          }
          input

in  Algebra.module Input Output run
