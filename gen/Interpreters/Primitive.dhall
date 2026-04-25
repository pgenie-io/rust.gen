let Deps = ../Deps/package.dhall

let Algebra = ../Algebras/package.dhall

let Input = Deps.Sdk.Project.Primitive

let Output =
      { sig : Text, pgType : Text, pgCastSuffix : Text, hasKnownPgType : Bool }

let unsupportedType =
      \(type : Text) ->
        Deps.Sdk.Compiled.report Output [ type ] "Unsupported type"

let known =
      \(sig : Text) ->
      \(pgType : Text) ->
        Deps.Sdk.Compiled.ok
          Output
          { sig, pgType, pgCastSuffix = "", hasKnownPgType = True }

let inferred =
      \(sig : Text) ->
        Deps.Sdk.Compiled.ok
          Output
          { sig
          , pgType = "Type::UNKNOWN"
          , pgCastSuffix = ""
          , hasKnownPgType = False
          }

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        merge
          { Bit = known "bit_vec::BitVec" "Type::BIT"
          , Bool = known "bool" "Type::BOOL"
          , Box = known "geo_types::Rect<f64>" "Type::BOX"
          , Bpchar = known "String" "Type::BPCHAR"
          , Bytea = known "Vec<u8>" "Type::BYTEA"
          , Char = known "i8" "Type::CHAR"
          , Cidr = known "cidr::IpCidr" "Type::CIDR"
          , Circle = unsupportedType "circle"
          , Citext = known "String" "Type::TEXT"
          , Date = known "chrono::NaiveDate" "Type::DATE"
          , Datemultirange = unsupportedType "datemultirange"
          , Daterange = unsupportedType "daterange"
          , Float4 = known "f32" "Type::FLOAT4"
          , Float8 = known "f64" "Type::FLOAT8"
          , Hstore =
              inferred "std::collections::HashMap<String, Option<String>>"
          , Inet = known "cidr::IpInet" "Type::INET"
          , Int2 = known "i16" "Type::INT2"
          , Int4 = known "i32" "Type::INT4"
          , Int4multirange = unsupportedType "int4multirange"
          , Int4range = unsupportedType "int4range"
          , Int8 = known "i64" "Type::INT8"
          , Int8multirange = unsupportedType "int8multirange"
          , Int8range = unsupportedType "int8range"
          , Interval = unsupportedType "interval"
          , Json = known "serde_json::Value" "Type::JSON"
          , Jsonb = known "serde_json::Value" "Type::JSONB"
          , Line = unsupportedType "line"
          , Lseg = unsupportedType "lseg"
          , Macaddr = known "eui48::MacAddress" "Type::MACADDR"
          , Macaddr8 = unsupportedType "macaddr8"
          , Money = unsupportedType "money"
          , Name = known "String" "Type::NAME"
          , Numeric = known "rust_decimal::Decimal" "Type::NUMERIC"
          , Nummultirange = unsupportedType "nummultirange"
          , Numrange = unsupportedType "numrange"
          , Oid = known "u32" "Type::OID"
          , Path = known "geo_types::LineString<f64>" "Type::PATH"
          , PgLsn = unsupportedType "pg_lsn"
          , PgSnapshot = unsupportedType "pg_snapshot"
          , Point = known "geo_types::Point<f64>" "Type::POINT"
          , Polygon = unsupportedType "polygon"
          , Text = known "String" "Type::TEXT"
          , Time = known "chrono::NaiveTime" "Type::TIME"
          , Timestamp = known "chrono::NaiveDateTime" "Type::TIMESTAMP"
          , Timestamptz =
              known "chrono::DateTime<chrono::Utc>" "Type::TIMESTAMPTZ"
          , Timetz = unsupportedType "timetz"
          , Tsmultirange = unsupportedType "tsmultirange"
          , Tsquery = unsupportedType "tsquery"
          , Tsrange = unsupportedType "tsrange"
          , Tstzmultirange = unsupportedType "tstzmultirange"
          , Tstzrange = unsupportedType "tstzrange"
          , Tsvector = unsupportedType "tsvector"
          , Uuid = known "uuid::Uuid" "Type::UUID"
          , Varbit = known "bit_vec::BitVec" "Type::VARBIT"
          , Varchar = known "String" "Type::VARCHAR"
          , Xml = unsupportedType "xml"
          , Box2D = unsupportedType "box2d"
          , Box3D = unsupportedType "box3d"
          , Geography = unsupportedType "geography"
          , Geometry = unsupportedType "geometry"
          , Ltree = unsupportedType "ltree"
          }
          input

in  Algebra.Interpreter.module Input Output run
