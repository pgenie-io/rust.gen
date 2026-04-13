# rust.gen

A [pGenie](https://github.com/pgenie-io/pgenie) plugin that generates type-safe Rust bindings for PostgreSQL using [tokio-postgres](https://crates.io/crates/tokio-postgres).

## What it generates

The plugin produces a self-contained Rust crate containing:

- **`Cargo.toml`** – a ready-to-build library with all required dependencies declared.
- **`src/mapping/`** – shared PostgreSQL statement mapping primitives:
  - A `Statement` trait with `SQL`, `PARAM_TYPES`, `RETURNS_ROWS`, `encode_params`, and `decode_result`.
  - A `DecodingError` enum and `decode_cell` helper for column-indexed result decoding.
- **`src/statements/*.rs`** – one module per SQL query. Each module contains:
  - An `Input` parameter struct with a field per query parameter.
  - An `Output` result type alias with a corresponding `OutputRow` type (for row-returning statements).
  - A `Statement` trait implementation that holds the SQL text, parameter types, and decoding logic.
- **`src/statements.rs`** – a module re-exporting all statement modules.
- **`src/types/*.rs`** – one module per custom PostgreSQL type:
  - **Enums** → Rust `enum` declarations with `#[derive(ToSql, FromSql)]` and `#[postgres(name = "...")]` attributes.
  - **Composite types** → Rust `struct` declarations with `#[derive(ToSql, FromSql)]` and per-field `#[postgres(name = "...")]` attributes.
- **`src/types.rs`** – a module re-exporting all type modules.

## Supported PostgreSQL types

Following is a summary of the supported PostgreSQL types and their Rust equivalents, using the
[`postgres-types`](https://docs.rs/postgres-types/latest/postgres_types/) crate.

### Supported Types

Scalar types can appear as plain values, as nullable values (`Option<T>`), or as arrays
of any dimensionality (`Vec<T>`, `Vec<Vec<T>>`, …) with controllable nullability of the
elements.

| PostgreSQL Type     | Rust Type                         | Crate             | Feature Flag / Version            |
|---------------------|-----------------------------------|-------------------|-----------------------------------|
| `bool`              | `bool`                            | std               | —                                 |
| `bytea`             | `Vec<u8>`                         | std               | —                                 |
| `char` (internal)   | `i8`                              | std               | —                                 |
| `int2` / `smallint` | `i16`                             | std               | —                                 |
| `int4` / `integer`  | `i32`                             | std               | —                                 |
| `int8` / `bigint`   | `i64`                             | std               | —                                 |
| `oid`               | `u32`                             | std               | —                                 |
| `float4` / `real`   | `f32`                             | std               | —                                 |
| `float8` / `double` | `f64`                             | std               | —                                 |
| `text`              | `String`                          | std               | —                                 |
| `varchar`           | `String`                          | std               | —                                 |
| `bpchar` / `char(n)`| `String`                          | std               | —                                 |
| `name`              | `String`                          | std               | —                                 |
| `citext`            | `String`                          | std               | —                                 |
| `cidr`              | `cidr::IpCidr`                    | `cidr` 0.3        | `with-cidr-0_3`                   |
| `inet`              | `cidr::IpInet`                    | `cidr` 0.3        | `with-cidr-0_3`                   |
| `hstore`            | `HashMap<String, Option<String>>` | std               | —                                 |
| `date`              | `chrono::NaiveDate`               | `chrono` 0.4      | `with-chrono-0_4`                 |
| `time`              | `chrono::NaiveTime`               | `chrono` 0.4      | `with-chrono-0_4`                 |
| `timestamp`         | `chrono::NaiveDateTime`           | `chrono` 0.4      | `with-chrono-0_4`                 |
| `timestamptz`       | `chrono::DateTime<chrono::Utc>`   | `chrono` 0.4      | `with-chrono-0_4`                 |
| `json`              | `serde_json::Value`               | `serde_json` 1    | `with-serde_json-1`               |
| `jsonb`             | `serde_json::Value`               | `serde_json` 1    | `with-serde_json-1`               |
| `uuid`              | `uuid::Uuid`                      | `uuid` 1          | `with-uuid-1`                     |
| `bit`               | `bit_vec::BitVec`                 | `bit-vec` 0.6     | `with-bit-vec-0_6`                |
| `varbit`            | `bit_vec::BitVec`                 | `bit-vec` 0.6     | `with-bit-vec-0_6`                |
| `macaddr`           | `eui48::MacAddress`               | `eui48` 1         | `with-eui48-1`                    |
| `point`             | `geo_types::Point<f64>`           | `geo-types` 0.7   | `with-geo-types-0_7`              |
| `box`               | `geo_types::Rect<f64>`            | `geo-types` 0.7   | `with-geo-types-0_7`              |
| `path`              | `geo_types::LineString<f64>`      | `geo-types` 0.7   | `with-geo-types-0_7`              |
| `numeric`           | `rust_decimal::Decimal`           | `rust_decimal` 1  | `db-postgres` (on `rust_decimal`) |

### Unsupported Types

The following PostgreSQL types defined in the gen-sdk do not have direct `ToSql`/`FromSql`
implementations in the `postgres-types` crate ecosystem. Statements using these types will
produce warnings and be skipped during generation.

| PostgreSQL Type     | Reason                                                                 |
|---------------------|------------------------------------------------------------------------|
| `circle`            | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `datemultirange`    | Multirange types not supported by `postgres-types`                     |
| `daterange`         | Range types not supported by `postgres-types`                          |
| `int4multirange`    | Multirange types not supported by `postgres-types`                     |
| `int4range`         | Range types not supported by `postgres-types`                          |
| `int8multirange`    | Multirange types not supported by `postgres-types`                     |
| `int8range`         | Range types not supported by `postgres-types`                          |
| `interval`          | No direct `ToSql`/`FromSql` impl in `postgres-types`                   |
| `line`              | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `lseg`              | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `macaddr8`          | `eui48` crate only supports 6-byte MAC (EUI-48), not 8-byte (EUI-64)   |
| `money`             | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `nummultirange`     | Multirange types not supported by `postgres-types`                     |
| `numrange`          | Range types not supported by `postgres-types`                          |
| `pg_lsn`            | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `pg_snapshot`       | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `polygon`           | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `timetz`            | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `tsmultirange`      | Multirange types not supported by `postgres-types`                     |
| `tsquery`           | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `tsrange`           | Range types not supported by `postgres-types`                          |
| `tstzmultirange`    | Multirange types not supported by `postgres-types`                     |
| `tstzrange`         | Range types not supported by `postgres-types`                          |
| `tsvector`          | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `xml`               | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `box2d`             | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `box3d`             | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `geography`         | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `geometry`          | No `ToSql`/`FromSql` impl in `postgres-types`                          |
| `ltree`             | No `ToSql`/`FromSql` impl in `postgres-types`                          |

### Notes

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

## Building

The generator is written in [Dhall](https://dhall-lang.org/). Install dhall by following the instructions at https://docs.dhall-lang.org/tutorials/Getting-started_Generate-JSON-or-YAML.html#linux.

To check the generator against the demo fixture:

```bash
dhall --file gen/demo.dhall
```

## Using the plugin in a pGenie project

Add the plugin to your pGenie project configuration file:

```yaml
space: my_space
name: music_catalogue
version: 1.0.0
artifacts:
  rust: https://raw.githubusercontent.com/pgenie-io/rust.gen/v0.1.1/gen/Gen.dhall
```

Run the code generator:

```bash
pgn generate
```

The generated crate will be placed in `artifacts/rust/`.

## Using the generated code

The generated crate is designed to be used directly from application code or from
integration tests. A small helper like `execute_preparing` can hide the boilerplate
of preparing statements, binding parameters, and decoding results while still
keeping the generated API visible.

The example below shows the pattern used in the demo tests: obtain a
`deadpool_postgres::Pool`, pull a client from the pool, prepare the generated
statement, and execute it through the generated `Statement` implementation.

```rust
use my_space_music_catalogue::mapping::Statement;
use my_space_music_catalogue::statements;
use my_space_music_catalogue::types;
use chrono::NaiveDate;

async fn execute_preparing<S: Statement>(
  pool: &deadpool_postgres::Pool,
  statement: &S,
) -> Result<S::Result, String> {
  let params = statement.encode_params();
  let client = pool
    .get()
    .await
    .map_err(|e| format!("Pool get: {e}"))?;

  let prepared = client
    .prepare_typed_cached(S::SQL, S::PARAM_TYPES)
    .await
    .map_err(|e| format!("Preparation error: {e}"))?;

  if S::RETURNS_ROWS {
    let rows = client
      .query(&prepared, params.as_ref())
      .await
      .map_err(|e| format!("Query: {e}"))?;
    let affected = rows.len() as u64;
    S::decode_result(rows, affected).map_err(|e| format!("Decoding: {e}"))
  } else {
    let affected = client
      .execute(&prepared, params.as_ref())
      .await
      .map_err(|e| format!("Execution: {e}"))?;
    S::decode_result(Vec::new(), affected).map_err(|e| format!("Decoding: {e}"))
  }
}

async fn example(pool: &deadpool_postgres::Pool) -> Result<(), String> {
  // Insert a real album record.
  let inserted = execute_preparing(
      pool,
      &statements::insert_album::Input {
        name: "Space Jazz Vol. 1".to_string(),
        released: NaiveDate::from_ymd_opt(2020, 5, 4).unwrap(),
        format: types::AlbumFormat::Vinyl,
        recording: types::RecordingInfo {
          studio_name: Some("Galactic Studio".to_string()),
          city: Some("Lunar City".to_string()),
          country: Some("Moon".to_string()),
          recorded_date: Some(NaiveDate::from_ymd_opt(2019, 12, 1).unwrap()),
        },
      }
  ).await?;
  // `insert_album` returns an `OutputRow` containing the new `id`.
  println!("Inserted album id={}", inserted.id);

  // Now query by name to demonstrate reading rows back.
  let rows = execute_preparing(
      pool,
      &statements::select_album_by_name::Input { name: "Space Jazz Vol. 1".to_string() }
  ).await?;

  for row in rows {
    println!(
      "Found album id={} name={} released={:?} format={:?} recording={:?}",
      row.id, row.name, row.released, row.format, row.recording
    );
  }

  Ok(())
}
```

If you are wiring generated bindings into your own project, implement a similar
utility function around deadpool_postgres. That keeps connection management in one
place and lets the generated `Statement` trait handle SQL text, parameter encoding,
and result decoding consistently across all statements.
