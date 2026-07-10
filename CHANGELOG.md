# Upcoming

## Non-breaking

- Bumped `gen-sdk` to v2.0.0, following the `Sdk.Sigs` restructuring: `Sigs.Interpreter.module`/`Sigs.Template.module` became lowercase `Sigs.interpreter`/`Sigs.template` (called directly as functions, no `.module` field), and the top-level entry point now builds its `Generator` via the new `Sdk.Sigs.generator Config defaultConfig interpret` in place of the removed `Contract.module`. No change to generated output.

- Restructured the repository layout to align with the pGenie generator architecture:
  - Generator implementation moved from `gen/` to `src/`.
  - Public entry point renamed from `gen/Gen.dhall` to `src/package.dhall`.
  - Internal `ResolvedTarget.dhall` renamed back to `InterpreterConfig.dhall`.
  - Fixture drivers moved from `tests/` to `demos/`; the materialised demo output is no longer committed.
  - Dropped the now-redundant `gen/Config.dhall` and `gen/compile.dhall` in favor of defining `Config`/`defaultConfig` directly in `src/package.dhall`.

- CI's `discover-tests` job is now `discover-demos`, matrixing over `demos/*.dhall` instead of `tests/*`, matching the `dhall-directory-tree.github-action@v2`-based generate-then-`cargo test` verification already in place.

# v1.0.0

## Breaking

- Updated `gen-sdk` to v0.11.0 and `lude.dhall` to v5.0.0, migrating to contract v4.0. 

# v0.4.2

## Non-breaking

- Removed the dependency on the custom fork of Dhall by working around the need for `Text/equal`.

# v0.4.1

## Non-breaking

- Add identity test generation

# v0.4.0

## Breaking

- Contract updated to v3.0

# v0.3.0

## Breaking

- Contract updated to v2.0

## Fixes

- Java keywords escaping

---

# v0.2.1

## Backwards compatible changes:

- Optional deadpool-postgres integration for generated crates. The mapping layer now exposes `Statement::execute_preparing` and `Statement::execute_without_preparing`, adds a unified `mapping::Error` type, and includes `deadpool-postgres` in generated dependencies when the integration is enabled.

---

# v0.1.1

## Fixes:

- Array types. The key change is that scalar values now carry explicit metadata for whether they have a concrete tokio-postgres type constant, and array values derive their PostgreSQL metadata from that instead of blindly reusing the scalar metadata. In practice, that means primitive arrays now emit Type::*_ARRAY for PARAM_TYPES, while generated cast suffixes are only injected for custom arrays. 

## Backwards compatible changes:

- gen-sdk updated to support the latest contract with the ltree and postgis extension types added.
