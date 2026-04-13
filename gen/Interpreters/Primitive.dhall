let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Input = Deps.Sdk.Project.Primitive

let Output = { sig : Text, pgType : Text }

let unsupportedType =
      \(type : Text) ->
        Deps.Sdk.Compiled.report Output [ type ] "Unsupported type"

let std =
      \(sig : Text) ->
      \(pgType : Text) ->
        Deps.Sdk.Compiled.ok Output { sig, pgType }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        merge
          { Bit = std "bit_vec::BitVec" "Type::BIT"
          , Bool = std "bool" "Type::BOOL"
          , Box = std "geo_types::Rect<f64>" "Type::BOX"
          , Bpchar = std "String" "Type::BPCHAR"
          , Bytea = std "Vec<u8>" "Type::BYTEA"
          , Char = std "i8" "Type::CHAR"
          , Cidr = std "cidr::IpCidr" "Type::CIDR"
          , Circle = unsupportedType "circle"
          , Citext = std "String" "Type::TEXT"
          , Date = std "chrono::NaiveDate" "Type::DATE"
          , Datemultirange = unsupportedType "datemultirange"
          , Daterange = unsupportedType "daterange"
          , Float4 = std "f32" "Type::FLOAT4"
          , Float8 = std "f64" "Type::FLOAT8"
          , Hstore =
              std
                "std::collections::HashMap<String, Option<String>>"
                "Type::TEXT"
          , Inet = std "cidr::IpInet" "Type::INET"
          , Int2 = std "i16" "Type::INT2"
          , Int4 = std "i32" "Type::INT4"
          , Int4multirange = unsupportedType "int4multirange"
          , Int4range = unsupportedType "int4range"
          , Int8 = std "i64" "Type::INT8"
          , Int8multirange = unsupportedType "int8multirange"
          , Int8range = unsupportedType "int8range"
          , Interval = unsupportedType "interval"
          , Json = std "serde_json::Value" "Type::JSON"
          , Jsonb = std "serde_json::Value" "Type::JSONB"
          , Line = unsupportedType "line"
          , Lseg = unsupportedType "lseg"
          , Macaddr = std "eui48::MacAddress" "Type::MACADDR"
          , Macaddr8 = unsupportedType "macaddr8"
          , Money = unsupportedType "money"
          , Name = std "String" "Type::NAME"
          , Numeric = std "rust_decimal::Decimal" "Type::NUMERIC"
          , Nummultirange = unsupportedType "nummultirange"
          , Numrange = unsupportedType "numrange"
          , Oid = std "u32" "Type::OID"
          , Path = std "geo_types::LineString<f64>" "Type::PATH"
          , PgLsn = unsupportedType "pg_lsn"
          , PgSnapshot = unsupportedType "pg_snapshot"
          , Point = std "geo_types::Point<f64>" "Type::POINT"
          , Polygon = unsupportedType "polygon"
          , Text = std "String" "Type::TEXT"
          , Time = std "chrono::NaiveTime" "Type::TIME"
          , Timestamp = std "chrono::NaiveDateTime" "Type::TIMESTAMP"
          , Timestamptz =
              std "chrono::DateTime<chrono::Utc>" "Type::TIMESTAMPTZ"
          , Timetz = unsupportedType "timetz"
          , Tsmultirange = unsupportedType "tsmultirange"
          , Tsquery = unsupportedType "tsquery"
          , Tsrange = unsupportedType "tsrange"
          , Tstzmultirange = unsupportedType "tstzmultirange"
          , Tstzrange = unsupportedType "tstzrange"
          , Tsvector = unsupportedType "tsvector"
          , Uuid = std "uuid::Uuid" "Type::UUID"
          , Varbit = std "bit_vec::BitVec" "Type::VARBIT"
          , Varchar = std "String" "Type::VARCHAR"
          , Xml = unsupportedType "xml"
          , Box2D = unsupportedType "box2d"
          , Box3D = unsupportedType "box3d"
          , Geography = unsupportedType "geography"
          , Geometry = unsupportedType "geometry"
          , Ltree = unsupportedType "ltree"
          }
          input

in  Algebra.module Input Output run
