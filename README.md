# rust.gen

A [pGenie](https://github.com/pgenie-io/pgenie) plugin that generates type-safe Rust bindings for PostgreSQL using [tokio-postgres](https://crates.io/crates/tokio-postgres).

## What it generates

For each pGenie project the plugin produces a self-contained Rust crate containing:

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

See [`type_mappings.md`](type_mappings.md) for the complete mapping table.

Scalar types can appear as plain values, as nullable values (`Option<T>`), or as arrays of any dimensionality (`Vec<T>`, `Vec<Vec<T>>`, …) with controllable nullability of array elements.

Unsupported types produce warnings and cause the affected statements to be skipped during generation.

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
  rust: https://raw.githubusercontent.com/pgenie-io/rust.gen/v0.1.0/gen/Gen.dhall
```

Run the code generator:

```bash
pgenie generate
```

The generated crate will be placed in `artifacts/rust/`.
