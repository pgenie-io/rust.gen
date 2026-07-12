#!/bin/bash -euo pipefail

# Local verification script for the Rust generator.
#
# CI already type-checks the Dhall, materialises the demo fixture, and runs the
# generated crate's tests on every push. This script reproduces those steps for
# local development convenience.

DEMO_OUTPUT_DIR="generated-output"

echo "Type-checking src/package.dhall"
dhall type --file src/package.dhall >/dev/null

echo "Regenerating demo output into ${DEMO_OUTPUT_DIR}"
rm -rf "${DEMO_OUTPUT_DIR}"
dhall to-directory-tree \
  --allow-path-separators \
  --file fixtures/Exhaustive.dhall \
  --output "${DEMO_OUTPUT_DIR}"

echo "Running generated crate tests"
cargo test --manifest-path "${DEMO_OUTPUT_DIR}/Cargo.toml"

echo "Done"
