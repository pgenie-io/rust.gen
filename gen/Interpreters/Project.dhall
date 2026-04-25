let Deps = ../Deps/package.dhall

let Algebra = ../Algebras/package.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Templates = ../Templates/package.dhall

let QueryGen = ./Query.dhall

let CustomTypeGen = ./CustomType.dhall

let Input = Model.Project

let Output = List Sdk.File.Type

let combineOutputs =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
      \(queries : List QueryGen.Output) ->
      \(customTypes : List CustomTypeGen.Output) ->
        let customTypeFiles
            : List Sdk.File.Type
            = Deps.Prelude.List.map
                CustomTypeGen.Output
                Sdk.File.Type
                ( \(customType : CustomTypeGen.Output) ->
                    { path = customType.modulePath
                    , content = customType.moduleContent
                    }
                )
                customTypes

        let statementFiles
            : List Sdk.File.Type
            = Deps.Prelude.List.map
                QueryGen.Output
                Sdk.File.Type
                ( \(query : QueryGen.Output) ->
                    { path = query.statementModulePath
                    , content = query.statementModuleContents
                    }
                )
                queries

        let migrationFiles
            : List Sdk.File.Type
            = Deps.Prelude.List.map
                { name : Text, sql : Text }
                Sdk.File.Type
                ( \(migration : { name : Text, sql : Text }) ->
                    { path = "migrations/${migration.name}.sql"
                    , content = migration.sql
                    }
                )
                input.migrations

        let typeModNames =
              Deps.Prelude.Text.concatMapSep
                "\n"
                CustomTypeGen.Output
                ( \(customType : CustomTypeGen.Output) ->
                    "mod ${customType.moduleName};"
                )
                customTypes

        let typeReexports =
              Deps.Prelude.Text.concatMapSep
                "\n"
                CustomTypeGen.Output
                ( \(customType : CustomTypeGen.Output) ->
                    "pub use ${customType.moduleName}::${customType.typeName};"
                )
                customTypes

        let stmtModNames =
              Deps.Prelude.Text.concatMapSep
                "\n"
                QueryGen.Output
                ( \(query : QueryGen.Output) ->
                    "pub mod ${query.statementModuleName};"
                )
                queries

        let libRs
            : Sdk.File.Type
            = { path = "src/lib.rs"
              , content =
                  Templates.LibRs.run { rootModuleName = config.rootModuleName }
              }

        let packageName =
              Deps.CodegenKit.Name.toTextInKebab
                (Deps.CodegenKit.Name.concat input.space [ input.name ])

        let cargoToml
            : Sdk.File.Type
            = { path = "Cargo.toml"
              , content =
                  Templates.CargoToml.run
                    { packageName
                    , version =
                            Natural/show input.version.major
                        ++  "."
                        ++  Natural/show input.version.minor
                        ++  "."
                        ++  Natural/show input.version.patch
                    , dbName = Deps.CodegenKit.Name.toTextInSnake input.name
                    , deadpool = config.deadpool
                    }
              }

        let mappingModRs
            : Sdk.File.Type
            = { path = "src/mapping.rs"
              , content =
                  if    config.deadpool
                  then  ''
                        //! Shared PostgreSQL statement mapping primitives.

                        mod decoding_error;
                        mod error;

                        use std::future::Future;

                        pub use decoding_error::DecodingError;
                        pub use error::Error;

                        /// Implemented by each query's parameter struct. Provides a uniform way to
                        /// prepare and execute statements against a [`tokio_postgres::Client`].
                        pub trait Statement {
                            /// The type returned when the statement is successfully executed.
                            type Result;

                            const SQL: &str;

                            const PARAM_TYPES: &'static [tokio_postgres::types::Type];

                            /// Encode `self` as a list of type-erased parameter references.
                            fn encode_params(&self) -> impl AsRef<[&(dyn tokio_postgres::types::ToSql + Sync)]> + Send;

                            /// Whether the statement returns rows.
                            const RETURNS_ROWS: bool;

                            fn decode_result(
                                rows: Vec<tokio_postgres::Row>,
                                affected_rows: u64,
                            ) -> Result<Self::Result, DecodingError>;

                            /// Execute the statement without preparing it first. This is less efficient than `execute_preparing` but is supported by all PostgreSQL proxies.
                            fn execute_without_preparing(
                                &self,
                                client: &deadpool_postgres::Client,
                            ) -> impl Future<Output = Result<Self::Result, Error>> + Send {
                                let params = self.encode_params();
                                async move {
                                    let params_borrowed = params.as_ref();

                                    if Self::RETURNS_ROWS {
                                        let rows = client.query(Self::SQL, params_borrowed).await?;
                                        let affected = rows.len() as u64;
                                        Self::decode_result(rows, affected).map_err(Error::Decoding)
                                    } else {
                                        let affected = client.execute(Self::SQL, params_borrowed).await?;
                                        Self::decode_result(Vec::new(), affected).map_err(Error::Decoding)
                                    }
                                }
                            }

                            /// Execute the statement automatically preparing it if necessary.
                            /// This is a more efficient way to execute parameteric statements, however it is unsupported by some PostgreSQL proxies like the older versions of `pgbouncer`.
                            /// 
                            /// Internally utilizes a prepared statement cache implemented by `deadpool-postgres`.
                            fn execute_preparing(
                                &self,
                                client: &deadpool_postgres::Client,
                            ) -> impl Future<Output = Result<Self::Result, Error>> + Send {
                                let params = self.encode_params();
                                async move {
                                    let params_borrowed = params.as_ref();

                                    let prepared = client
                                        .prepare_typed_cached(Self::SQL, Self::PARAM_TYPES)
                                        .await?;

                                    if Self::RETURNS_ROWS {
                                        let rows = client.query(&prepared, params_borrowed).await?;
                                        let affected = rows.len() as u64;
                                        Self::decode_result(rows, affected).map_err(Error::Decoding)
                                    } else {
                                        let affected = client.execute(&prepared, params_borrowed).await?;
                                        Self::decode_result(Vec::new(), affected).map_err(Error::Decoding)
                                    }
                                }
                            }
                        }

                        /// Decode a single result-set cell and attach its row/column location to any
                        /// PostgreSQL decoding error.
                        pub fn decode_cell<'a, T: tokio_postgres::types::FromSql<'a>>(
                            input_row: &'a tokio_postgres::Row,
                            row_index: usize,
                            column_index: usize,
                        ) -> Result<T, DecodingError> {
                            input_row
                                .try_get(column_index)
                                .map_err(|source| DecodingError::Cell {
                                    row: row_index,
                                    column: column_index,
                                    source,
                                })
                        }
                        ''
                  else  ''
                        //! Shared PostgreSQL statement mapping primitives.

                        mod decoding_error;
                        pub use decoding_error::DecodingError;

                        /// Implemented by each query's parameter struct. Provides a uniform way to
                        /// prepare and execute statements against a [`tokio_postgres::Client`].
                        pub trait Statement {
                            /// The type returned when the statement is successfully executed.
                            type Result;

                            const SQL: &str;

                            const PARAM_TYPES: &'static [tokio_postgres::types::Type];

                            /// Encode `self` as a list of type-erased parameter references.
                            fn encode_params(&self) -> impl AsRef<[&(dyn tokio_postgres::types::ToSql + Sync)]>;

                            /// Whether the statement returns rows.
                            const RETURNS_ROWS: bool;

                            fn decode_result(
                                rows: Vec<tokio_postgres::Row>,
                                affected_rows: u64,
                            ) -> Result<Self::Result, DecodingError>;
                        }

                        /// Decode a single result-set cell and attach its row/column location to any
                        /// PostgreSQL decoding error.
                        pub fn decode_cell<'a, T: tokio_postgres::types::FromSql<'a>>(
                            input_row: &'a tokio_postgres::Row,
                            row_index: usize,
                            column_index: usize,
                        ) -> Result<T, DecodingError> {
                            input_row
                                .try_get(column_index)
                                .map_err(|source| DecodingError::Cell {
                                    row: row_index,
                                    column: column_index,
                                    source,
                                })
                        }
                        ''
              }

        let decodingErrorRs =
              { path = "src/mapping/decoding_error.rs"
              , content =
                  ''
                  #[derive(Debug)]
                  pub enum DecodingError {
                      UnexpectedAmountOfRows {
                          expected: usize,
                          actual: usize,
                      },
                      Cell {
                          row: usize,
                          column: usize,
                          source: tokio_postgres::Error,
                      },
                  }

                  impl std::fmt::Display for DecodingError {
                      fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                          match self {
                              DecodingError::UnexpectedAmountOfRows { expected, actual } => {
                                  write!(f, "expected {expected} row(s), got {actual}")
                              }
                              DecodingError::Cell {
                                  row,
                                  column,
                                  source: error,
                              } => {
                                  write!(f, "error at row {row}, column {column}: {error}")
                              }
                          }
                      }
                  }

                  impl std::error::Error for DecodingError {
                      fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
                          match self {
                              DecodingError::Cell { source: error, .. } => Some(error),
                              DecodingError::UnexpectedAmountOfRows { .. } => None,
                          }
                      }
                  }
                  ''
              }

        let deadpoolFiles
            : List Sdk.File.Type
            = if    config.deadpool
              then  [ { path = "src/mapping/error.rs"
                      , content =
                          ''
                          use super::DecodingError;

                          pub enum Error {
                              Decoding(DecodingError),
                              Deadpool(deadpool_postgres::PoolError),
                              Postgres(tokio_postgres::Error),
                          }

                          impl From<DecodingError> for Error {
                              fn from(value: DecodingError) -> Self {
                                  Self::Decoding(value)
                              }
                          }
                          impl From<deadpool_postgres::PoolError> for Error {
                              fn from(value: deadpool_postgres::PoolError) -> Self {
                                  Self::Deadpool(value)
                              }
                          }
                          impl From<tokio_postgres::Error> for Error {
                              fn from(value: tokio_postgres::Error) -> Self {
                                  Self::Postgres(value)
                              }
                          }
                          ''
                      }
                    ]
              else  [] : List Sdk.File.Type

        let statementsRs
            : Sdk.File.Type
            = { path = "src/statements.rs"
              , content =
                  ''
                  //! Mappings to all queries in the project.
                  //!
                  //! Each sub-module exposes a parameter struct that implements [`crate::mapping::Statement`].

                  ${stmtModNames}
                  ''
              }

        let typesRs
            : Sdk.File.Type
            = { path = "src/types.rs"
              , content =
                  ''
                  ${typeModNames}
                  ${typeReexports}
                  ''
              }

        let crateName =
              Deps.CodegenKit.Name.toTextInSnake
                (Deps.CodegenKit.Name.concat input.space [ input.name ])

        let stmtAsserts =
              Deps.Prelude.Text.concatMapSep
                "\n"
                QueryGen.Output
                ( \(query : QueryGen.Output) ->
                    "    assert_statement_executes::<statements::${query.statementModuleName}::Input>(&pool, \"${query.statementModuleName}\").await;"
                )
                queries

        let migrationEntries
            : Text
            = Deps.Prelude.Text.concatMapSep
                "\n"
                { name : Text, sql : Text }
                ( \(migration : { name : Text, sql : Text }) ->
                    "        (\"${migration.name}.sql\", include_str!(\"../migrations/${migration.name}.sql\")),"
                )
                input.migrations

        let testsRs
            : Sdk.File.Type
            = { path = "tests/tests.rs"
              , content =
                  ''
                  use std::error::Error;

                  use ${crateName}::mapping::Statement;
                  use ${crateName}::statements;
                  use testcontainers::runners::AsyncRunner as _;

                  async fn setup_pool() -> (
                      deadpool_postgres::Pool,
                      testcontainers::ContainerAsync<testcontainers_modules::postgres::Postgres>,
                  ) {
                      let container = testcontainers_modules::postgres::Postgres::default()
                          .start()
                          .await
                          .expect("Failed to start Postgres container");

                      let host_port = container
                          .get_host_port_ipv4(5432)
                          .await
                          .expect("Failed to get host port");

                      let mut cfg = deadpool_postgres::Config::new();
                      cfg.host = Some("127.0.0.1".to_string());
                      cfg.port = Some(host_port);
                      cfg.user = Some("postgres".to_string());
                      cfg.password = Some("postgres".to_string());
                      cfg.dbname = Some("postgres".to_string());

                      let pool = cfg
                          .create_pool(
                              Some(deadpool_postgres::Runtime::Tokio1),
                              tokio_postgres::NoTls,
                          )
                          .expect("Failed to create pool");

                      apply_migrations(host_port).await;

                      (pool, container)
                  }

                  async fn apply_migrations(host_port: u16) {
                      const MIGRATIONS: &[(&str, &str)] = &[
                  ${migrationEntries}
                      ];

                      let (client, conn) = tokio_postgres::connect(
                          &format!(
                              "host=127.0.0.1 port={} user=postgres password=postgres dbname=postgres",
                              host_port
                          ),
                          tokio_postgres::NoTls,
                      )
                      .await
                      .expect("Failed to connect for migrations");

                      tokio::spawn(async move {
                          if let Err(e) = conn.await {
                              eprintln!("migration connection error: {e}");
                          }
                      });

                      for (name, sql) in MIGRATIONS {
                          client
                              .batch_execute(sql)
                              .await
                              .unwrap_or_else(|e| panic!("Migration {name} failed: {e}"));
                      }
                  }

                  async fn execute_preparing<S: ${crateName}::mapping::Statement>(
                      pool: &deadpool_postgres::Pool,
                      statement: &S,
                  ) -> Result<S::Result, String> {
                      let params = statement.encode_params();
                      let client = pool
                          .get()
                          .await
                          .map_err(|e| format!("Pool get: {}", e.to_string()))?;
                      let prepared = client
                          .prepare_typed_cached(S::SQL, S::PARAM_TYPES)
                          .await
                          .map_err(|e| {
                              format!(
                                  "Preparation error: {}\nSource: {}",
                                  e.to_string(),
                                  e.source()
                                      .map_or("unknown".into(), |source| source.to_string())
                              )
                          })?;
                      if S::RETURNS_ROWS {
                          let rows = client
                              .query(&prepared, params.as_ref())
                              .await
                              .map_err(|e| format!("Query: {}", e.to_string()))?;
                          let affected = rows.len() as u64;
                          S::decode_result(rows, affected).map_err(|e| format!("Decoding: {}", e.to_string()))
                      } else {
                          let affected = client
                              .execute(&prepared, params.as_ref())
                              .await
                              .map_err(|e| format!("Execution: {}", e.to_string()))?;
                          S::decode_result(vec![], affected).map_err(|e| format!("Decoding: {}", e.to_string()))
                      }
                  }

                  async fn assert_statement_executes<S>(pool: &deadpool_postgres::Pool, stmt_name: &str)
                  where
                      S: Statement + Default,
                  {
                      let statement = S::default();
                      execute_preparing(pool, &statement)
                          .await
                          .unwrap_or_else(|e| panic!("Statement {stmt_name} should execute successfully: {e}"));
                  }

                  #[tokio::test]
                  async fn all_declared_statements_execute_with_default_values() {
                      let (pool, _container) = setup_pool().await;
                  ${stmtAsserts}
                  }
                  ''
              }

        in      [ cargoToml
                , libRs
                , mappingModRs
                , decodingErrorRs
                , typesRs
                , statementsRs
                , testsRs
                ]
              # deadpoolFiles
              # migrationFiles
              # customTypeFiles
              # statementFiles
            : List Sdk.File.Type

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        let compiledQueries
            : Sdk.Compiled.Type (List (Optional QueryGen.Output))
            = Sdk.Compiled.traverseList
                Deps.Sdk.Project.Query
                (Optional QueryGen.Output)
                ( \(query : Deps.Sdk.Project.Query) ->
                    Deps.Typeclasses.Classes.Alternative.optional
                      Sdk.Compiled.Type
                      Sdk.Compiled.alternative
                      QueryGen.Output
                      (QueryGen.run config query)
                )
                input.queries

        let compiledQueries
            : Sdk.Compiled.Type (List QueryGen.Output)
            = Sdk.Compiled.map
                (List (Optional QueryGen.Output))
                (List QueryGen.Output)
                (Deps.Prelude.List.unpackOptionals QueryGen.Output)
                compiledQueries

        let compiledTypes
            : Sdk.Compiled.Type (List CustomTypeGen.Output)
            = Sdk.Compiled.traverseList
                Deps.Sdk.Project.CustomType
                CustomTypeGen.Output
                (CustomTypeGen.run config)
                input.customTypes

        let files
            : Sdk.Compiled.Type (List Sdk.File.Type)
            = Sdk.Compiled.map2
                (List QueryGen.Output)
                (List CustomTypeGen.Output)
                (List Sdk.File.Type)
                (combineOutputs config input)
                compiledQueries
                compiledTypes

        in  files

in  Algebra.Interpreter.module Input Output run
