let Deps = ../Deps/package.dhall

let Algebra = ../Algebras/package.dhall

let Input = Deps.Sdk.Project.Primitive

let Output =
      { sig : Text
      , pgType : Text
      , pgCastSuffix : Text
      , hasKnownPgType : Bool
      , supportsDefault : Bool
      }

let unsupportedType =
      \(type : Text) ->
        Deps.Sdk.Compiled.report Output [ type ] "Unsupported type"

let known =
      \(sig : Text) ->
      \(pgType : Text) ->
      \(supportsDefault : Bool) ->
        Deps.Sdk.Compiled.ok
          Output
          { sig
          , pgType
          , pgCastSuffix = ""
          , hasKnownPgType = True
          , supportsDefault
          }

let inferred =
      \(sig : Text) ->
        Deps.Sdk.Compiled.ok
          Output
          { sig
          , pgType = "Type::UNKNOWN"
          , pgCastSuffix = ""
          , hasKnownPgType = False
          , supportsDefault = True
          }

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        merge
          { Bit = known "bit_vec::BitVec" "Type::BIT" True
          , Bool = known "bool" "Type::BOOL" True
          , Box = known "geo_types::Rect<f64>" "Type::BOX" False
          , Bpchar = known "String" "Type::BPCHAR" True
          , Bytea = known "Vec<u8>" "Type::BYTEA" True
          , Char = known "i8" "Type::CHAR" True
          , Cidr = known "cidr::IpCidr" "Type::CIDR" False
          , Circle = unsupportedType "circle"
          , Citext = known "String" "Type::TEXT" True
          , Date = known "chrono::NaiveDate" "Type::DATE" True
          , Datemultirange = unsupportedType "datemultirange"
          , Daterange = unsupportedType "daterange"
          , Float4 = known "f32" "Type::FLOAT4" True
          , Float8 = known "f64" "Type::FLOAT8" True
          , Hstore =
              inferred "std::collections::HashMap<String, Option<String>>"
          , Inet = known "cidr::IpInet" "Type::INET" False
          , Int2 = known "i16" "Type::INT2" True
          , Int4 = known "i32" "Type::INT4" True
          , Int4multirange = unsupportedType "int4multirange"
          , Int4range = unsupportedType "int4range"
          , Int8 = known "i64" "Type::INT8" True
          , Int8multirange = unsupportedType "int8multirange"
          , Int8range = unsupportedType "int8range"
          , Interval = unsupportedType "interval"
          , Json = known "serde_json::Value" "Type::JSON" True
          , Jsonb = known "serde_json::Value" "Type::JSONB" True
          , Line = unsupportedType "line"
          , Lseg = unsupportedType "lseg"
          , Macaddr = known "eui48::MacAddress" "Type::MACADDR" True
          , Macaddr8 = unsupportedType "macaddr8"
          , Money = unsupportedType "money"
          , Name = known "String" "Type::NAME" True
          , Numeric = known "rust_decimal::Decimal" "Type::NUMERIC" True
          , Nummultirange = unsupportedType "nummultirange"
          , Numrange = unsupportedType "numrange"
          , Oid = known "u32" "Type::OID" True
          , Path = known "geo_types::LineString<f64>" "Type::PATH" False
          , PgLsn = unsupportedType "pg_lsn"
          , PgSnapshot = unsupportedType "pg_snapshot"
          , Point = known "geo_types::Point<f64>" "Type::POINT" True
          , Polygon = unsupportedType "polygon"
          , Text = known "String" "Type::TEXT" True
          , Time = known "chrono::NaiveTime" "Type::TIME" True
          , Timestamp = known "chrono::NaiveDateTime" "Type::TIMESTAMP" True
          , Timestamptz =
              known "chrono::DateTime<chrono::Utc>" "Type::TIMESTAMPTZ" True
          , Timetz = unsupportedType "timetz"
          , Tsmultirange = unsupportedType "tsmultirange"
          , Tsquery = unsupportedType "tsquery"
          , Tsrange = unsupportedType "tsrange"
          , Tstzmultirange = unsupportedType "tstzmultirange"
          , Tstzrange = unsupportedType "tstzrange"
          , Tsvector = unsupportedType "tsvector"
          , Uuid = known "uuid::Uuid" "Type::UUID" True
          , Varbit = known "bit_vec::BitVec" "Type::VARBIT" True
          , Varchar = known "String" "Type::VARCHAR" True
          , Xml = unsupportedType "xml"
          , Box2D = unsupportedType "box2d"
          , Box3D = unsupportedType "box3d"
          , Geography = unsupportedType "geography"
          , Geometry = unsupportedType "geometry"
          , Ltree = unsupportedType "ltree"
          }
          input

in  Algebra.Interpreter.module Input Output run
