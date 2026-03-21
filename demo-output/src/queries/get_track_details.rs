//! Query module for `get_track_details`.
//!
//! SQL:
//! ```sql
//! SELECT t.id, t.title, t.duration_seconds, a.name as album_title,
//!        ar.name as artist_name, g.name as genre, a.album_type
//! FROM track t
//! JOIN album a ON t.album_id = a.id
//! JOIN artist ar ON a.artist_id = ar.id
//! LEFT JOIN genre g ON t.genre_id = g.id
//! WHERE t.id = $track_id
//! ```
//!
//! Source: `queries/get_track_details.sql`

use tokio_postgres::Client;

/// Parameters for the `get_track_details` query.
#[derive(Debug, Clone)]
pub struct GetTrackDetailsParams {
    /// Maps to `track_id`.
    pub track_id: uuid::Uuid,
}

/// Result of the `GetTrackDetails` query.
pub type GetTrackDetailsResult = Option<GetTrackDetailsResultRow>;

/// Row of [`GetTrackDetailsResult`].
#[derive(Debug, Clone)]
pub struct GetTrackDetailsResultRow {
    /// Maps to `id`.
    pub id: uuid::Uuid,
    /// Maps to `title`.
    pub title: String,
    /// Maps to `duration_seconds`.
    pub duration_seconds: Option<i32>,
    /// Maps to `album_title`.
    pub album_title: String,
    /// Maps to `artist_name`.
    pub artist_name: String,
    /// Maps to `genre`.
    pub genre: Option<String>,
    /// Maps to `album_type`.
    pub album_type: crate::types::AlbumType,
}

impl From<tokio_postgres::Row> for GetTrackDetailsResultRow {
    fn from(row: tokio_postgres::Row) -> Self {
        Self {
            id: row.get("id"),
            title: row.get("title"),
            duration_seconds: row.get("duration_seconds"),
            album_title: row.get("album_title"),
            artist_name: row.get("artist_name"),
            genre: row.get("genre"),
            album_type: row.get("album_type"),
        }
    }
}

/// SQL query string.
pub const SQL: &str = "SELECT t.id, t.title, t.duration_seconds, a.name as album_title, ar.name as artist_name, g.name as genre, a.album_type\nFROM track t\nJOIN album a ON t.album_id = a.id\nJOIN artist ar ON a.artist_id = ar.id\nLEFT JOIN genre g ON t.genre_id = g.id\nWHERE t.id = $1";

/// Execute the `get_track_details` query.
pub async fn query(
    client: &Client,
    params: &GetTrackDetailsParams,
) -> Result<GetTrackDetailsResult, tokio_postgres::Error> {
    let row = client.query_opt(SQL, &[&params.track_id as &(dyn postgres_types::ToSql + Sync)]).await?;
    Ok(row.map(|row| row.into()))
}
