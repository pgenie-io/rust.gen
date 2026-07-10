let Sdk = ../Deps/Sdk.dhall

let ResolvedTarget = ../ResolvedTarget.dhall

let Lude = ../Deps/Lude.dhall

let Contract = ../Deps/Contract.dhall

let Input = Contract.Primitive

let Output =
      { sig : Text
      , pgType : Text
      , pgCastSuffix : Text
      , hasKnownPgType : Bool
      , supportsDefault : Bool
      , testValueExpr : Text
      }

let unsupportedType =
      \(type : Text) -> Lude.Compiled.report Output [ type ] "Unsupported type"

let known =
      \(sig : Text) ->
      \(pgType : Text) ->
      \(supportsDefault : Bool) ->
      \(testValueExpr : Text) ->
        Lude.Compiled.ok
          Output
          { sig
          , pgType
          , pgCastSuffix = ""
          , hasKnownPgType = True
          , supportsDefault
          , testValueExpr
          }

let inferred =
      \(sig : Text) ->
      \(testValueExpr : Text) ->
        Lude.Compiled.ok
          Output
          { sig
          , pgType = "Type::UNKNOWN"
          , pgCastSuffix = ""
          , hasKnownPgType = False
          , supportsDefault = True
          , testValueExpr
          }

let run =
      \(config : ResolvedTarget.Type) ->
      \(input : Input) ->
        merge
          { Bit =
              known
                "bit_vec::BitVec"
                "Type::BIT"
                True
                "bit_vec::BitVec::from_elem(1, true)"
          , Bool = known "bool" "Type::BOOL" True "true"
          , Box =
              known
                "geo_types::Rect<f64>"
                "Type::BOX"
                False
                "geo_types::Rect::new(geo_types::Coord { x: 0.0, y: 0.0 }, geo_types::Coord { x: 1.0, y: 1.0 })"
          , Bpchar = known "String" "Type::BPCHAR" True "\"a\".to_string()"
          , Bytea =
              known
                "Vec<u8>"
                "Type::BYTEA"
                True
                "vec![0xDEu8, 0xAD, 0xBE, 0xEF]"
          , Char = known "i8" "Type::CHAR" True "65i8"
          , Cidr =
              known
                "cidr::IpCidr"
                "Type::CIDR"
                False
                "\"192.168.0.0/24\".parse::<cidr::IpCidr>().unwrap()"
          , Circle = unsupportedType "circle"
          , Citext = known "String" "Type::TEXT" True "\"Hello\".to_string()"
          , Date =
              known
                "chrono::NaiveDate"
                "Type::DATE"
                True
                "chrono::NaiveDate::from_ymd_opt(2024, 1, 15).unwrap()"
          , Datemultirange = unsupportedType "datemultirange"
          , Daterange = unsupportedType "daterange"
          , Float4 = known "f32" "Type::FLOAT4" True "3.14f32"
          , Float8 = known "f64" "Type::FLOAT8" True "2.718f64"
          , Hstore = unsupportedType "hstore"
          , Inet =
              known
                "cidr::IpInet"
                "Type::INET"
                False
                "\"192.168.1.1/24\".parse::<cidr::IpInet>().unwrap()"
          , Int2 = known "i16" "Type::INT2" True "42i16"
          , Int4 = known "i32" "Type::INT4" True "42i32"
          , Int8 = known "i64" "Type::INT8" True "42i64"
          , Int4multirange = unsupportedType "int4multirange"
          , Int4range = unsupportedType "int4range"
          , Int8multirange = unsupportedType "int8multirange"
          , Int8range = unsupportedType "int8range"
          , Interval = unsupportedType "interval"
          , Json =
              known
                "serde_json::Value"
                "Type::JSON"
                True
                "serde_json::json!({\"key\": \"value\"})"
          , Jsonb =
              known
                "serde_json::Value"
                "Type::JSONB"
                True
                "serde_json::json!([1, 2, 3])"
          , Line = unsupportedType "line"
          , Lseg = unsupportedType "lseg"
          , Macaddr =
              known
                "eui48::MacAddress"
                "Type::MACADDR"
                True
                "eui48::MacAddress::new([0xDE, 0xAD, 0xBE, 0xEF, 0x00, 0x01])"
          , Macaddr8 = unsupportedType "macaddr8"
          , Money = unsupportedType "money"
          , Name = known "String" "Type::NAME" True "\"my_name\".to_string()"
          , Numeric =
              known
                "rust_decimal::Decimal"
                "Type::NUMERIC"
                True
                "rust_decimal::Decimal::new(123456, 3)"
          , Nummultirange = unsupportedType "nummultirange"
          , Numrange = unsupportedType "numrange"
          , Oid = known "u32" "Type::OID" True "42u32"
          , Path =
              known
                "geo_types::LineString<f64>"
                "Type::PATH"
                False
                "geo_types::LineString::from(vec![geo_types::Coord { x: 0.0, y: 0.0 }, geo_types::Coord { x: 1.0, y: 1.0 }])"
          , PgLsn = unsupportedType "pg_lsn"
          , PgSnapshot = unsupportedType "pg_snapshot"
          , Point =
              known
                "geo_types::Point<f64>"
                "Type::POINT"
                True
                "geo_types::Point::new(1.0, 2.0)"
          , Polygon = unsupportedType "polygon"
          , Text =
              known "String" "Type::TEXT" True "\"hello world\".to_string()"
          , Time =
              known
                "chrono::NaiveTime"
                "Type::TIME"
                True
                "chrono::NaiveTime::from_hms_opt(12, 30, 45).unwrap()"
          , Timestamp =
              known
                "chrono::NaiveDateTime"
                "Type::TIMESTAMP"
                True
                "chrono::NaiveDateTime::new(chrono::NaiveDate::from_ymd_opt(2024, 1, 15).unwrap(), chrono::NaiveTime::from_hms_opt(12, 30, 45).unwrap())"
          , Timestamptz =
              known
                "chrono::DateTime<chrono::Utc>"
                "Type::TIMESTAMPTZ"
                True
                "chrono::DateTime::from_timestamp(1_705_324_245, 0).unwrap()"
          , Timetz = unsupportedType "timetz"
          , Tsmultirange = unsupportedType "tsmultirange"
          , Tsquery = unsupportedType "tsquery"
          , Tsrange = unsupportedType "tsrange"
          , Tstzmultirange = unsupportedType "tstzmultirange"
          , Tstzrange = unsupportedType "tstzrange"
          , Tsvector = unsupportedType "tsvector"
          , Uuid =
              known
                "uuid::Uuid"
                "Type::UUID"
                True
                "uuid::Uuid::from_u128(0x1234567890abcdef1234567890abcdef)"
          , Varbit =
              known
                "bit_vec::BitVec"
                "Type::VARBIT"
                True
                "bit_vec::BitVec::from_bytes(&[0b10101010])"
          , Varchar =
              known "String" "Type::VARCHAR" True "\"hello\".to_string()"
          , Xml = unsupportedType "xml"
          , Box2D = unsupportedType "box2d"
          , Box3D = unsupportedType "box3d"
          , Geography = unsupportedType "geography"
          , Geometry = unsupportedType "geometry"
          , Ltree = unsupportedType "ltree"
          }
          input

in  Sdk.Sigs.Interpreter.module ResolvedTarget.Type Input Output run
