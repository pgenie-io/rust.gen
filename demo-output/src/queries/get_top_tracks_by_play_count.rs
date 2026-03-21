//! Query module for `get_top_tracks_by_play_count`.
//!
//! SQL:
//! ```sql
//! SELECT t.id, t.title, t.play_count, a.name as album_name, ar.name as artist_name
//! FROM track t
//! JOIN album a ON t.album_id = a.id
//! JOIN artist ar ON a.artist_id = ar.id
//! ORDER BY t.play_count DESC
//! LIMIT $limit
//! ```
//!
//! Source: `queries/get_top_tracks_by_play_count.sql`

use tokio_postgres::Client;

/// Parameters for the `get_top_tracks_by_play_count` query.
#[derive(Debug, Clone)]
pub struct GetTopTracksByPlayCountParams {
    /// Maps to `limit`.
    pub limit: i32,
}

/// Result of the `GetTopTracksByPlayCount` query.
pub type GetTopTracksByPlayCountResult = Vec<GetTopTracksByPlayCountResultRow>;

/// Row of [`GetTopTracksByPlayCountResult`].
#[derive(Debug, Clone)]
pub struct GetTopTracksByPlayCountResultRow {
    /// Maps to `id`.
    pub id: uuid::Uuid,
    /// Maps to `title`.
    pub title: String,
    /// Maps to `play_count`.
    pub play_count: Option<i32>,
    /// Maps to `album_name`.
    pub album_name: String,
    /// Maps to `artist_name`.
    pub artist_name: String,
}

impl From<tokio_postgres::Row> for GetTopTracksByPlayCountResultRow {
    fn from(row: tokio_postgres::Row) -> Self {
        Self {
            id: row.get("id"),
            title: row.get("title"),
            play_count: row.get("play_count"),
            album_name: row.get("album_name"),
            artist_name: row.get("artist_name"),
        }
    }
}

/// SQL query string.
pub const SQL: &str = "SELECT t.id, t.title, t.play_count, a.name as album_name, ar.name as artist_name\nFROM track t\nJOIN album a ON t.album_id = a.id\nJOIN artist ar ON a.artist_id = ar.id\nORDER BY t.play_count DESC\nLIMIT $1";

/// Execute the `get_top_tracks_by_play_count` query.
pub async fn query(
    client: &Client,
    params: &GetTopTracksByPlayCountParams,
) -> Result<GetTopTracksByPlayCountResult, tokio_postgres::Error> {
    let rows = client.query(SQL, &[&params.limit as &(dyn postgres_types::ToSql + Sync)]).await?;
    Ok(rows.into_iter().map(|row| row.into()).collect())
}
