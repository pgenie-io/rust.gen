use postgres_types::ToSql;

/// SQL query string.
pub const SQL: &str = "select id, genre.name\n\
from genre\n\
left join album_genre on album_genre.genre = genre.id\n\
left join album_artist on album_artist.album = album_genre.album\n\
where album_artist.artist = $1";

/// Parameters for the `select_genre_by_artist` query.
///
/// # SQL
///
/// select id, genre.name
/// from genre
/// left join album_genre on album_genre.genre = genre.id
/// left join album_artist on album_artist.album = album_genre.album
/// where album_artist.artist = $artist
///
/// # Source
///
/// `./queries/select_genre_by_artist.sql`
#[derive(Debug, Clone)]
pub struct Input {
/// Maps to `artist`.
pub artist: i32,

}

impl Input {
    pub fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
        vec![&self.artist]
    }
}

/// Output type: multiple rows.
pub type Output = Vec<OutputRow>;

/// Row of the output.
#[derive(Debug, Clone)]
pub struct OutputRow {
/// Maps to `id`.
pub id: i32,
/// Maps to `name`.
pub name: String,
}

impl OutputRow {
    pub fn from_row(row: &tokio_postgres::Row) -> Self {
        Self {
            id: row.get("id"),
            name: row.get("name"),
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

