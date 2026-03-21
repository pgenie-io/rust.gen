//! Query module for `search_tracks_by_title`.
//!
//! SQL:
//! ```sql
//! SELECT t.id, t.title, t.duration_seconds, a.name as album_name, ar.name as artist_name
//! FROM track t
//! JOIN album a ON t.album_id = a.id
//! JOIN artist ar ON a.artist_id = ar.id
//! WHERE t.title ILIKE '%' || $search_term || '%'
//! ORDER BY t.title
//! ```
//!
//! Source: `queries/search_tracks_by_title.sql`

use tokio_postgres::Client;

/// Parameters for the `search_tracks_by_title` query.
#[derive(Debug, Clone)]
pub struct SearchTracksByTitleParams {
    /// Maps to `search_term`.
    pub search_term: String,
}

/// Result of the `SearchTracksByTitle` query.
pub type SearchTracksByTitleResult = Vec<SearchTracksByTitleResultRow>;

/// Row of [`SearchTracksByTitleResult`].
#[derive(Debug, Clone)]
pub struct SearchTracksByTitleResultRow {
    /// Maps to `id`.
    pub id: uuid::Uuid,
    /// Maps to `title`.
    pub title: String,
    /// Maps to `duration_seconds`.
    pub duration_seconds: Option<i32>,
    /// Maps to `album_name`.
    pub album_name: String,
    /// Maps to `artist_name`.
    pub artist_name: String,
}

impl From<tokio_postgres::Row> for SearchTracksByTitleResultRow {
    fn from(row: tokio_postgres::Row) -> Self {
        Self {
            id: row.get("id"),
            title: row.get("title"),
            duration_seconds: row.get("duration_seconds"),
            album_name: row.get("album_name"),
            artist_name: row.get("artist_name"),
        }
    }
}

/// SQL query string.
pub const SQL: &str = "SELECT t.id, t.title, t.duration_seconds, a.name as album_name, ar.name as artist_name\nFROM track t\nJOIN album a ON t.album_id = a.id\nJOIN artist ar ON a.artist_id = ar.id\nWHERE t.title ILIKE '%' || $1 || '%'\nORDER BY t.title";

/// Execute the `search_tracks_by_title` query.
pub async fn query(
    client: &Client,
    params: &SearchTracksByTitleParams,
) -> Result<SearchTracksByTitleResult, tokio_postgres::Error> {
    let rows = client.query(SQL, &[&params.search_term as &(dyn postgres_types::ToSql + Sync)]).await?;
    Ok(rows.into_iter().map(|row| row.into()).collect())
}
