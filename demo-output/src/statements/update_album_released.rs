use postgres_types::ToSql;

/// SQL query string.
pub const SQL: &str = "update album\n\
set released = $1\n\
where id = $2";

/// Parameters for the `update_album_released` query.
///
/// # SQL
///
/// update album
/// set released = $released
/// where id = $id
///
/// # Source
///
/// `./queries/update_album_released.sql`
#[derive(Debug, Clone)]
pub struct Input {
/// Maps to `released`.
pub released: Option<chrono::NaiveDate>,
/// Maps to `id`.
pub id: i64,

}

impl Input {
    pub fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
        vec![&self.released, &self.id]
    }
}

/// Output type: number of rows affected.
pub type Output = u64;

impl crate::Statement for Input {
    type Output = Output;

    fn sql() -> &'static str {
        SQL
    }

    fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
        self.params()
    }

    fn decode(_rows: Vec<tokio_postgres::Row>, rows_affected: u64) -> Self::Output {
        rows_affected
    }
}

