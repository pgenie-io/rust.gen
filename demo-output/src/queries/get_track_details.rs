//! Query module for `get_track_details`.
//!
//! SQL:
//! ```sql
//! SELECT 
//!     t.id,
//!     t.title,
//!     t.duration_seconds,
//!     t.track_number,
//!     a.id as album_id,
//!     a.title as album_title,
//!     ar.id as artist_id,
//!     ar.name as artist_name,
//!     g.name as genre
//! FROM tracks t
//! JOIN albums a ON t.album_id = a.id
//! JOIN artists ar ON a.artist_id = ar.id
//! LEFT JOIN genres g ON t.genre_id = g.id
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
pub type GetTrackDetailsResult = GetTrackDetailsResultRow;

/// Row of [`GetTrackDetailsResult`].
#[derive(Debug, Clone)]
pub struct GetTrackDetailsResultRow {
    /// Maps to `id`.
    pub id: uuid::Uuid,
    /// Maps to `title`.
    pub title: String,
    /// Maps to `duration_seconds`.
    pub duration_seconds: Option<i32>,
    /// Maps to `track_number`.
    pub track_number: Option<i32>,
    /// Maps to `album_id`.
    pub album_id: uuid::Uuid,
    /// Maps to `album_title`.
    pub album_title: String,
    /// Maps to `artist_id`.
    pub artist_id: uuid::Uuid,
    /// Maps to `artist_name`.
    pub artist_name: String,
    /// Maps to `genre`.
    pub genre: Option<String>,
}

impl From<tokio_postgres::Row> for GetTrackDetailsResultRow {
    fn from(row: tokio_postgres::Row) -> Self {
        Self {
            id: row.get("id"),
            title: row.get("title"),
            duration_seconds: row.get("duration_seconds"),
            track_number: row.get("track_number"),
            album_id: row.get("album_id"),
            album_title: row.get("album_title"),
            artist_id: row.get("artist_id"),
            artist_name: row.get("artist_name"),
            genre: row.get("genre"),
        }
    }
}

/// SQL query string.
pub const SQL: &str = "SELECT \n    t.id,\n    t.title,\n    t.duration_seconds,\n    t.track_number,\n    a.id as album_id,\n    a.title as album_title,\n    ar.id as artist_id,\n    ar.name as artist_name,\n    g.name as genre\nFROM tracks t\nJOIN albums a ON t.album_id = a.id\nJOIN artists ar ON a.artist_id = ar.id\nLEFT JOIN genres g ON t.genre_id = g.id\nWHERE t.id = $1";

/// Execute the `get_track_details` query.
pub async fn query(
    client: &Client,
    params: &GetTrackDetailsParams,
) -> Result<GetTrackDetailsResult, tokio_postgres::Error> {
    let row = client.query_one(SQL, &[&params.track_id as &(dyn postgres_types::ToSql + Sync)]).await?;
    Ok(row.into())
}
