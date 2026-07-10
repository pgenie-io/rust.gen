let Lude = ../Deps/Lude.dhall

let Sdk = ../Deps/Sdk.dhall

let Params = { crateName : Text, migrationEntries : Text, stmtTests : Text }

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
          ''
          use std::error::Error;

          use ${params.crateName}::statements;
          use testcontainers::runners::AsyncRunner as _;

          struct SharedTestContext {
              pool: deadpool_postgres::Pool,
              _container: testcontainers::ContainerAsync<testcontainers_modules::postgres::Postgres>,
          }

          static SHARED_TEST_CONTEXT: tokio::sync::OnceCell<std::sync::Mutex<Option<SharedTestContext>>> =
              tokio::sync::OnceCell::const_new();

          #[dtor::dtor(unsafe, method = at_module_exit)]
          fn cleanup_shared_test_context() {
              if let Some(context) = SHARED_TEST_CONTEXT.get() {
                  if let Some(context) = context.lock().unwrap().take() {
                      std::thread::spawn(move || {
                          let runtime = tokio::runtime::Builder::new_current_thread()
                              .enable_all()
                              .build()
                              .expect("Failed to build cleanup runtime");

                          runtime.block_on(async move {
                              drop(context);
                          });
                      })
                      .join()
                      .expect("Failed to join cleanup thread");
                  }
              }
          }

          async fn setup_pool() -> std::sync::Mutex<Option<SharedTestContext>> {
              let container = testcontainers_modules::postgres::Postgres::default()
                  .start()
                  .await
                  .expect("Failed to start Postgres container");

              let host_port = container
                  .get_host_port_ipv4(5432)
                  .await
                  .expect("Failed to get host port");

              let mut cfg = deadpool_postgres::Config::new();
              cfg.manager = Some(deadpool_postgres::ManagerConfig {
                  recycling_method: deadpool_postgres::RecyclingMethod::Verified,
              });
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

              std::sync::Mutex::new(Some(SharedTestContext {
                  pool,
                  _container: container,
              }))
          }

          async fn shared_pool() -> deadpool_postgres::Pool {
              SHARED_TEST_CONTEXT
                  .get_or_init(setup_pool)
                  .await
                  .lock()
                  .unwrap()
                  .as_ref()
                  .expect("Shared test context should be initialized")
                  .pool
                  .clone()
          }

          async fn apply_migrations(host_port: u16) {
              const MIGRATIONS: &[(&str, &str)] = &[
                  ${Lude.Text.indentNonEmpty 8 params.migrationEntries}
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

          async fn execute_preparing<S: ${params.crateName}::mapping::Statement>(
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

          ${params.stmtTests}
          ''
      )
