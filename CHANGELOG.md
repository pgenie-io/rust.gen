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
