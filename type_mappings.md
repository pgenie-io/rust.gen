# PostgreSQL to Rust Type Mappings

This document summarizes the associations between PostgreSQL types as defined in the
[gen-sdk `Project.dhall`](https://github.com/pgenie-io/gen-sdk/blob/v0.1.0/dhall/Project.dhall#L10-L127)
and their Rust equivalents, using the
[`postgres-types`](https://docs.rs/postgres-types/latest/postgres_types/) crate's
[`ToSql`](https://docs.rs/postgres-types/latest/postgres_types/trait.ToSql.html) and
[`FromSql`](https://docs.rs/postgres-types/latest/postgres_types/trait.FromSql.html) trait implementations.

## Supported Types

Scalar types can appear as plain values, as nullable values (`Option<T>`), or as arrays
of any dimensionality (`Vec<T>`, `Vec<Vec<T>>`, …) with controllable nullability of the
elements.

| PostgreSQL Type     | Rust Type                                        | Crate                   | Feature Flag / Version       |
|---------------------|--------------------------------------------------|-------------------------|------------------------------|
| `bool`              | `bool`                                           | std                     | —                            |
| `bytea`             | `Vec<u8>`                                        | std                     | —                            |
| `char` (internal)   | `i8`                                             | std                     | —                            |
| `int2` / `smallint` | `i16`                                            | std                     | —                            |
| `int4` / `integer`  | `i32`                                            | std                     | —                            |
| `int8` / `bigint`   | `i64`                                            | std                     | —                            |
| `oid`               | `u32`                                            | std                     | —                            |
| `float4` / `real`   | `f32`                                            | std                     | —                            |
| `float8` / `double` | `f64`                                            | std                     | —                            |
| `text`              | `String`                                         | std                     | —                            |
| `varchar`           | `String`                                         | std                     | —                            |
| `bpchar` / `char(n)`| `String`                                         | std                     | —                            |
| `name`              | `String`                                         | std                     | —                            |
| `citext`            | `String`                                         | std                     | —                            |
| `inet`              | `std::net::IpAddr`                               | std                     | —                            |
| `hstore`            | `std::collections::HashMap<String, Option<String>>`| std                    | —                            |
| `date`              | `chrono::NaiveDate`                              | `chrono` 0.4            | `with-chrono-0_4`            |
| `time`              | `chrono::NaiveTime`                              | `chrono` 0.4            | `with-chrono-0_4`            |
| `timestamp`         | `chrono::NaiveDateTime`                          | `chrono` 0.4            | `with-chrono-0_4`            |
| `timestamptz`       | `chrono::DateTime<chrono::Utc>`                  | `chrono` 0.4            | `with-chrono-0_4`            |
| `json`              | `serde_json::Value`                              | `serde_json` 1          | `with-serde_json-1`          |
| `jsonb`             | `serde_json::Value`                              | `serde_json` 1          | `with-serde_json-1`          |
| `uuid`              | `uuid::Uuid`                                     | `uuid` 1                | `with-uuid-1`                |
| `bit`               | `bit_vec::BitVec`                                | `bit-vec` 0.6           | `with-bit-vec-0_6`           |
| `varbit`            | `bit_vec::BitVec`                                | `bit-vec` 0.6           | `with-bit-vec-0_6`           |
| `macaddr`           | `eui48::MacAddress`                              | `eui48` 1               | `with-eui48-1`               |
| `point`             | `geo_types::Point<f64>`                          | `geo-types` 0.7         | `with-geo-types-0_7`         |
| `box`               | `geo_types::Rect<f64>`                           | `geo-types` 0.7         | `with-geo-types-0_7`         |
| `path`              | `geo_types::LineString<f64>`                     | `geo-types` 0.7         | `with-geo-types-0_7`         |
| `numeric`           | `rust_decimal::Decimal`                          | `rust_decimal` 1        | `db-postgres` (on `rust_decimal`) |

## Unsupported Types

The following PostgreSQL types defined in the gen-sdk do not have direct `ToSql`/`FromSql`
implementations in the `postgres-types` crate ecosystem. Statements using these types will
produce warnings and be skipped during generation.

| PostgreSQL Type     | Reason                                                                 |
|---------------------|------------------------------------------------------------------------|
| `cidr`              | No `ToSql`/`FromSql` impl in `postgres-types`                         |
| `circle`            | No `ToSql`/`FromSql` impl in `postgres-types`                         |
| `datemultirange`    | Multirange types not supported by `postgres-types`                     |
| `daterange`         | Range types not supported by `postgres-types`                          |
| `int4multirange`    | Multirange types not supported by `postgres-types`                     |
| `int4range`         | Range types not supported by `postgres-types`                          |
| `int8multirange`    | Multirange types not supported by `postgres-types`                     |
| `int8range`         | Range types not supported by `postgres-types`                          |
| `interval`          | No direct `ToSql`/`FromSql` impl in `postgres-types`                  |
| `line`              | No `ToSql`/`FromSql` impl in `postgres-types`                         |
| `lseg`              | No `ToSql`/`FromSql` impl in `postgres-types`                         |
| `macaddr8`          | `eui48` crate only supports 6-byte MAC (EUI-48), not 8-byte (EUI-64)  |
| `money`             | No `ToSql`/`FromSql` impl in `postgres-types`                         |
| `nummultirange`     | Multirange types not supported by `postgres-types`                     |
| `numrange`          | Range types not supported by `postgres-types`                          |
| `pg_lsn`            | No `ToSql`/`FromSql` impl in `postgres-types`                         |
| `pg_snapshot`       | No `ToSql`/`FromSql` impl in `postgres-types`                         |
| `polygon`           | No `ToSql`/`FromSql` impl in `postgres-types`                         |
| `timetz`            | No `ToSql`/`FromSql` impl in `postgres-types`                         |
| `tsmultirange`      | Multirange types not supported by `postgres-types`                     |
| `tsquery`           | No `ToSql`/`FromSql` impl in `postgres-types`                         |
| `tsrange`           | Range types not supported by `postgres-types`                          |
| `tstzmultirange`    | Multirange types not supported by `postgres-types`                     |
| `tstzrange`         | Range types not supported by `postgres-types`                          |
| `tsvector`          | No `ToSql`/`FromSql` impl in `postgres-types`                         |
| `xml`               | No `ToSql`/`FromSql` impl in `postgres-types`                         |

## Notes

- **Nullable types**: When a PostgreSQL column is nullable, the Rust type is wrapped in
  `Option<T>`.
- **Array types**: PostgreSQL arrays map to `Vec<T>` (one-dimensional) or nested `Vec`s
  for multi-dimensional arrays. Element nullability is controlled by wrapping the element
  type in `Option<T>`.
- **Custom types**: User-defined PostgreSQL enums generate Rust enums with `ToSql`/`FromSql`
  derive macros. Composite types generate Rust structs with the same derives. Composite
  types that contain unsupported field types are skipped, along with any statements
  referencing them.
- **Domain types**: Not yet supported by this generator.
