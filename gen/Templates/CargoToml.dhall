let Algebra = ./Algebra/package.dhall

let Params =
      { packageName : Text
      , version : Text
      , dbName : Text
      }

in  Algebra.module
      Params
      ( \(params : Params) ->
          ''
          [package]
          name = "${params.packageName}"
          version = "${params.version}"
          edition = "2021"
          description = "Type-safe mapping to the ${params.dbName} database"

          [dependencies]
          tokio-postgres = { version = "0.7", features = [
              "with-chrono-0_4",
              "with-uuid-1",
              "with-serde_json-1",
          ] }
          postgres-types = { version = "0.2", features = [
              "derive",
              "with-chrono-0_4",
              "with-uuid-1",
          ] }
          chrono = { version = "0.4", default-features = false, features = ["std"] }
          ''
      )
