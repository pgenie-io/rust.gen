use postgres_types::ToSql;

/// SQL query string.
pub const SQL: &str = "insert into album (name, released, format, recording)\n\
values ($1, $2, $3, $4)\n\
returning id";

/// Parameters for the `insert_album` query.
///
/// # SQL
///
/// insert into album (name, released, format, recording)
/// values ($name, $released, $format, $recording)
/// returning id
///
/// # Source
///
/// `./queries/insert_album.sql`
#[derive(Debug, Clone)]
pub struct Input {
/// Maps to `name`.
pub name: String,
/// Maps to `released`.
pub released: chrono::NaiveDate,
/// Maps to `format`.
pub format: crate::types::AlbumFormat,
/// Maps to `recording`.
pub recording: crate::types::RecordingInfo,

}

impl Input {
    pub fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
        vec![&self.name, &self.released, &self.format, &self.recording]
    }
}

/// Output type: exactly one row.
pub type Output = OutputRow;

/// Row of the output.
#[derive(Debug, Clone)]
pub struct OutputRow {
/// Maps to `id`.
pub id: i64,
}

impl OutputRow {
    pub fn from_row(row: &tokio_postgres::Row) -> Self {
        Self {
            id: row.get("id"),
        }
    }
}


impl crate::Statement for Input {
    type Output = Output;

    fn sql() -> &'static str {
        SQL
    }

    fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
        self.params()
    }

    fn decode(rows: Vec<tokio_postgres::Row>, _rows_affected: u64) -> Self::Output {
        let row = rows.into_iter().next().expect("expected exactly one row");
        OutputRow::from_row(&row)
    }
}

