use postgres_types::ToSql;

/// SQL query string.
pub const SQL: &str = "select id, name, tracks, disc\n\
from album\n\
where id = $1";

/// Parameters for the `select_album_with_tracks` query.
///
/// # SQL
///
/// select id, name, tracks, disc
/// from album
/// where id = $id
///
/// # Source
///
/// `./queries/select_album_with_tracks.sql`
#[derive(Debug, Clone)]
pub struct Input {
/// Maps to `id`.
pub id: i64,

}

impl Input {
    pub fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
        vec![&self.id]
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
/// Maps to `tracks`.
pub tracks: Option<Vec<crate::types::TrackInfo>>,
/// Maps to `disc`.
pub disc: Option<crate::types::DiscInfo>,
}

impl OutputRow {
    pub fn from_row(row: &tokio_postgres::Row) -> Self {
        Self {
            id: row.get("id"),
            name: row.get("name"),
            tracks: row.get("tracks"),
            disc: row.get("disc"),
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

