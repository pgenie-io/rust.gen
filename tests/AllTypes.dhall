-- Intended to be executed with:
--
-- ```bash
-- dhall to-directory-tree --file tests/AllTypes.dhall --output demo-output --allow-path-separators
-- ```
--
-- This generates the demo output for the music_catalogue fixture project.
let Fixtures = ../gen/Deps/Fixtures.dhall

let Gen = ../gen/Gen.dhall

let project = Fixtures.AllTypes

let compiledFiles = Gen.compileToFileMap (Some { deadpool = True }) project

in  compiledFiles
