use postgres_types::ToSql;

/// SQL query string.
pub const SQL: &str = "select\n\
  id,\n\
  name,\n\
  released,\n\
  format,\n\
  recording\n\
from album\n\
where name = $1";

/// Parameters for the `select_album_by_name` query.
///
/// # SQL
///
/// select
///   id,
///   name,
///   released,
///   format,
///   recording
/// from album
/// where name = $name
///
/// # Source
///
/// `./queries/select_album_by_name.sql`
#[derive(Debug, Clone)]
pub struct Input {
/// Maps to `name`.
pub name: String,

}

impl Input {
    pub fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
        vec![&self.name]
    }
}

/// Output type: multiple rows.
pub type Output = Vec<OutputRow>;

/// Row of the output.
#[derive(Debug, Clone)]
pub struct OutputRow {
/// Maps to `id`.
pub id: i64,
/// Maps to `name`.
pub name: String,
/// Maps to `released`.
pub released: Option<chrono::NaiveDate>,
/// Maps to `format`.
pub format: Option<crate::types::AlbumFormat>,
/// Maps to `recording`.
pub recording: Option<crate::types::RecordingInfo>,
}

impl OutputRow {
    pub fn from_row(row: &tokio_postgres::Row) -> Self {
        Self {
            id: row.get("id"),
            name: row.get("name"),
            released: row.get("released"),
            format: row.get("format"),
            recording: row.get("recording"),
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
        rows.iter().map(|row| OutputRow::from_row(row)).collect()
    }
}

