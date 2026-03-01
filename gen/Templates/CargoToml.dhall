let Deps = ../Deps/package.dhall

let Input = { packageName : Text, version : Text, dbName : Text }

let run =
      \(input : Input) ->
        ''
        [package]
        name = "${input.packageName}"
        version = "${input.version}"
        edition = "2021"
        description = "Type-safe mapping to the \"${input.dbName}\" database"

        [dependencies]
        tokio-postgres = { version = "0.7", features = ["with-chrono-0_4", "with-uuid-1", "with-serde_json-1"] }
        postgres-types = { version = "0.2", features = ["derive", "with-chrono-0_4", "with-uuid-1", "with-serde_json-1"] }
        tokio = { version = "1", features = ["full"] }
        chrono = { version = "0.4", features = ["serde"] }
        uuid = { version = "1", features = ["serde", "v4"] }
        serde = { version = "1", features = ["derive"] }
        serde_json = "1"
        rust_decimal = { version = "1", features = ["db-tokio-postgres"] }
        bytes = "1"
        ''

in  { Input, run }
