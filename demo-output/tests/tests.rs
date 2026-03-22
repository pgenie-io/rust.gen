use my_space_music_catalogue::mapping::Statement;
use my_space_music_catalogue::statements;
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
    const MIGRATIONS: &[(&str, &str)] = &[];

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

async fn execute_preparing<S: my_space_music_catalogue::mapping::Statement>(
    pool: &deadpool_postgres::Pool,
    statement: &S,
) -> Result<S::Result, String> {
    let params = statement.encode_params();
    let client = pool.get().await.map_err(|e| e.to_string())?;
    let prepared = client
        .prepare_typed_cached(S::SQL, S::PARAM_TYPES)
        .await
        .map_err(|e| e.to_string())?;
    if S::RETURNS_ROWS {
        let rows = client
            .query(&prepared, params.as_ref())
            .await
            .map_err(|e| e.to_string())?;
        let affected = rows.len() as u64;
        S::decode_result(rows, affected).map_err(|e| e.to_string())
    } else {
        let affected = client
            .execute(&prepared, params.as_ref())
            .await
            .map_err(|e| e.to_string())?;
        S::decode_result(vec![], affected).map_err(|e| e.to_string())
    }
}

async fn assert_statement_executes<S>(pool: &deadpool_postgres::Pool)
where
    S: Statement + Default,
{
    let statement = S::default();
    execute_preparing(pool, &statement)
        .await
        .expect("statement should execute successfully");
}

#[tokio::test]
async fn all_declared_statements_execute_with_default_values() {
    let (pool, _container) = setup_pool().await;
    assert_statement_executes::<my_space_music_catalogue::statements::insert_album::Input>(&pool).await;
    assert_statement_executes::<my_space_music_catalogue::statements::select_album_by_format::Input>(&pool).await;
    assert_statement_executes::<my_space_music_catalogue::statements::select_album_by_name::Input>(&pool).await;
    assert_statement_executes::<my_space_music_catalogue::statements::select_album_with_tracks::Input>(&pool).await;
    assert_statement_executes::<my_space_music_catalogue::statements::select_genre_by_artist::Input>(&pool).await;
    assert_statement_executes::<my_space_music_catalogue::statements::update_album_recording_returning::Input>(&pool).await;
    assert_statement_executes::<my_space_music_catalogue::statements::update_album_released::Input>(&pool).await;
}
