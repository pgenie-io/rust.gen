# PostgreSQL to Rust Type Mappings

This document summarizes the associations between PostgreSQL types (as defined in the
[gen-sdk `Primitive` type](https://github.com/pgenie-io/gen-sdk/blob/v0.1.0/dhall/Project.dhall#L10-L127))
and Rust types, based on the [`postgres-types`](https://docs.rs/postgres-types/latest/postgres_types/) crate's
[`ToSql`](https://docs.rs/postgres-types/latest/postgres_types/trait.ToSql.html) and
[`FromSql`](https://docs.rs/postgres-types/latest/postgres_types/trait.FromSql.html) trait implementations.

## Supported Types

| gen-sdk Primitive | PostgreSQL Type | Rust Type | Crate | Crate Version | `postgres-types` Feature |
|---|---|---|---|---|---|
| `Bit` | `bit` (OID 1560) | `bit_vec::BitVec` | `bit-vec` | 0.6 | `with-bit-vec-0_6` |
| `Bool` | `bool` (OID 16) | `bool` | std | — | — |
| `Box` | `box` (OID 603) | `geo_types::Rect<f64>` | `geo-types` | 0.7 | `with-geo-types-0_7` |
| `Bpchar` | `bpchar` / `char(n)` (OID 1042) | `String` | std | — | — |
| `Bytea` | `bytea` (OID 17) | `Vec<u8>` | std | — | — |
| `Char` | `"char"` (OID 18) | `i8` | std | — | — |
| `Citext` | `citext` (extension) | `String` | std | — | — |
| `Date` | `date` (OID 1082) | `chrono::NaiveDate` | `chrono` | 0.4 | `with-chrono-0_4` |
| `Float4` | `float4` / `real` (OID 700) | `f32` | std | — | — |
| `Float8` | `float8` / `double precision` (OID 701) | `f64` | std | — | — |
| `Hstore` | `hstore` (extension) | `std::collections::HashMap<String, Option<String>>` | std | — | — |
| `Inet` | `inet` (OID 869) | `std::net::IpAddr` | std | — | — |
| `Int2` | `int2` / `smallint` (OID 21) | `i16` | std | — | — |
| `Int4` | `int4` / `integer` (OID 23) | `i32` | std | — | — |
| `Int8` | `int8` / `bigint` (OID 20) | `i64` | std | — | — |
| `Json` | `json` (OID 114) | `serde_json::Value` | `serde_json` | 1 | `with-serde_json-1` |
| `Jsonb` | `jsonb` (OID 3802) | `serde_json::Value` | `serde_json` | 1 | `with-serde_json-1` |
| `Macaddr` | `macaddr` (OID 829) | `eui48::MacAddress` | `eui48` | 1 | `with-eui48-1` |
| `Name` | `name` (OID 19) | `String` | std | — | — |
| `Numeric` | `numeric` (OID 1700) | `rust_decimal::Decimal` | `rust_decimal` | 1 | `db-tokio-postgres` (on `rust_decimal`) |
| `Oid` | `oid` | `u32` | std | — | — |
| `Path` | `path` (OID 602) | `geo_types::LineString<f64>` | `geo-types` | 0.7 | `with-geo-types-0_7` |
| `Point` | `point` (OID 600) | `geo_types::Point<f64>` | `geo-types` | 0.7 | `with-geo-types-0_7` |
| `Text` | `text` (OID 25) | `String` | std | — | — |
| `Time` | `time` (OID 1083) | `chrono::NaiveTime` | `chrono` | 0.4 | `with-chrono-0_4` |
| `Timestamp` | `timestamp` (OID 1114) | `chrono::NaiveDateTime` | `chrono` | 0.4 | `with-chrono-0_4` |
| `Timestamptz` | `timestamptz` (OID 1184) | `chrono::DateTime<chrono::Utc>` | `chrono` | 0.4 | `with-chrono-0_4` |
| `Uuid` | `uuid` (OID 2950) | `uuid::Uuid` | `uuid` | 1 | `with-uuid-1` |
| `Varbit` | `varbit` (OID 1562) | `bit_vec::BitVec` | `bit-vec` | 0.6 | `with-bit-vec-0_6` |
| `Varchar` | `varchar` (OID 1043) | `String` | std | — | — |

## Unsupported Types

The following PostgreSQL types do not have `ToSql`/`FromSql` implementations in the `postgres-types` crate
and are **not supported** by this generator. Statements using these types will be skipped with a warning.
Composite types that contain fields of unsupported types will also be skipped.

| gen-sdk Primitive | PostgreSQL Type | Reason |
|---|---|---|
| `Cidr` | `cidr` (OID 650) | Requires the `cidr` crate; `ToSql` not available via `std::net::IpAddr` (only `FromSql` supports CIDR via `IpAddr`). |
| `Circle` | `circle` (OID 718) | No `ToSql`/`FromSql` implementation in `postgres-types`. |
| `Datemultirange` | `datemultirange` (OID 4535) | Range/multirange types not supported by `postgres-types`. |
| `Daterange` | `daterange` (OID 3912) | Range types not supported by `postgres-types`. |
| `Int4multirange` | `int4multirange` (OID 4451) | Range/multirange types not supported by `postgres-types`. |
| `Int4range` | `int4range` (OID 3904) | Range types not supported by `postgres-types`. |
| `Int8multirange` | `int8multirange` (OID 4536) | Range/multirange types not supported by `postgres-types`. |
| `Int8range` | `int8range` (OID 3926) | Range types not supported by `postgres-types`. |
| `Interval` | `interval` (OID 1186) | No `ToSql`/`FromSql` implementation in `postgres-types`. |
| `Line` | `line` (OID 628) | No `ToSql`/`FromSql` implementation in `postgres-types`. |
| `Lseg` | `lseg` (OID 601) | No `ToSql`/`FromSql` implementation in `postgres-types`. |
| `Macaddr8` | `macaddr8` (OID 774) | No `ToSql`/`FromSql` implementation in `postgres-types` (`eui48` only supports `macaddr`). |
| `Money` | `money` (OID 790) | No `ToSql`/`FromSql` implementation in `postgres-types`. |
| `Nummultirange` | `nummultirange` (OID 4532) | Range/multirange types not supported by `postgres-types`. |
| `Numrange` | `numrange` (OID 3906) | Range types not supported by `postgres-types`. |
| `PgLsn` | `pg_lsn` (OID 3220) | No `ToSql`/`FromSql` implementation in `postgres-types`. |
| `PgSnapshot` | `pg_snapshot` (OID 5038) | No `ToSql`/`FromSql` implementation in `postgres-types`. |
| `Polygon` | `polygon` (OID 604) | No `ToSql`/`FromSql` implementation in `postgres-types`. |
| `Timetz` | `timetz` (OID 1266) | No `ToSql`/`FromSql` implementation in `postgres-types`. |
| `Tsmultirange` | `tsmultirange` (OID 4533) | Range/multirange types not supported by `postgres-types`. |
| `Tsquery` | `tsquery` (OID 3615) | No `ToSql`/`FromSql` implementation in `postgres-types`. |
| `Tsrange` | `tsrange` (OID 3908) | Range types not supported by `postgres-types`. |
| `Tstzmultirange` | `tstzmultirange` (OID 4534) | Range/multirange types not supported by `postgres-types`. |
| `Tstzrange` | `tstzrange` (OID 3910) | Range types not supported by `postgres-types`. |
| `Tsvector` | `tsvector` (OID 3614) | No `ToSql`/`FromSql` implementation in `postgres-types`. |
| `Xml` | `xml` (OID 142) | No `ToSql`/`FromSql` implementation in `postgres-types`. |

## Cargo Dependencies

The following dependencies are required in the generated `Cargo.toml`:

```toml
[dependencies]
tokio-postgres = { version = "0.7", features = [
    "with-chrono-0_4",
    "with-uuid-1",
    "with-serde_json-1",
    "with-eui48-1",
    "with-geo-types-0_7",
    "with-bit-vec-0_6",
] }
postgres-types = { version = "0.2", features = [
    "derive",
    "with-chrono-0_4",
    "with-uuid-1",
    "with-serde_json-1",
    "with-eui48-1",
    "with-geo-types-0_7",
    "with-bit-vec-0_6",
] }
tokio = { version = "1", features = ["full"] }
chrono = { version = "0.4", features = ["serde"] }
uuid = { version = "1", features = ["serde", "v4"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
rust_decimal = { version = "1", features = ["db-tokio-postgres"] }
bytes = "1"
eui48 = { version = "1", features = ["serde"] }
geo-types = "0.7"
bit-vec = "0.6"
```

## Notes

- **Nullability**: Nullable PostgreSQL columns/parameters are represented as `Option<T>` in Rust.
- **Arrays**: PostgreSQL arrays are represented as `Vec<T>` in Rust (requires `array-impls` feature on `postgres-types`).
- **Custom types**: PostgreSQL enum types use `#[derive(ToSql, FromSql)]` with `#[postgres(name = "...")]` attributes. Composite types also use derive macros.
- **Unsupported type handling**: When a statement uses an unsupported type, the generator produces a warning and skips that statement. Composite types with unsupported field types are also skipped, along with any statements that reference them.
