# Upcoming

## Non-breaking

- Bumped `gen-contract` to v5.0.0 and `gen-sdk` to v3.0.0.
- Behavior change: a custom type this generator can't render (currently: `Domain`), or any custom type/query that transitively depends on one, is now skipped with a warning instead of hard-failing the entire project compile.

## Fixes

- `Scalar.Custom` references to a custom type now use that type's authentic `pgSchema`/`pgName` (from the resolvable `CustomTypeRef`) for the generated Postgres cast suffix, instead of fabricating `::public.<name.inSnakeCase>` — which was structurally wrong for any custom type outside the `public` schema, or whose Postgres name differs from the identifier's own snake_case rendering.

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
