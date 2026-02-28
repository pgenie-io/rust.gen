//! Query module for `get_top_tracks_by_play_count`.
//!
//! SQL:
//! ```sql
//! SELECT 
//!     t.id,
//!     t.title,
//!     ar.name as artist_name,
//!     a.title as album_title,
//!     COALESCE(p.play_count, 0) as play_count
//! FROM tracks t
//! JOIN albums a ON t.album_id = a.id
//! JOIN artists ar ON a.artist_id = ar.id
//! LEFT JOIN (
//!     SELECT track_id, COUNT(*) as play_count
//!     FROM play_history
//!     GROUP BY track_id
//! ) p ON t.id = p.track_id
//! ORDER BY play_count DESC
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
    /// Maps to `artist_name`.
    pub artist_name: String,
    /// Maps to `album_title`.
    pub album_title: String,
    /// Maps to `play_count`.
    pub play_count: i32,
}

impl From<tokio_postgres::Row> for GetTopTracksByPlayCountResultRow {
    fn from(row: tokio_postgres::Row) -> Self {
        Self {
            id: row.get("id"),
            title: row.get("title"),
            artist_name: row.get("artist_name"),
            album_title: row.get("album_title"),
            play_count: row.get("play_count"),
        }
    }
}

/// SQL query string.
pub const SQL: &str = "SELECT \n    t.id,\n    t.title,\n    ar.name as artist_name,\n    a.title as album_title,\n    COALESCE(p.play_count, 0) as play_count\nFROM tracks t\nJOIN albums a ON t.album_id = a.id\nJOIN artists ar ON a.artist_id = ar.id\nLEFT JOIN (\n    SELECT track_id, COUNT(*) as play_count\n    FROM play_history\n    GROUP BY track_id\n) p ON t.id = p.track_id\nORDER BY play_count DESC\nLIMIT $1";

/// Execute the `get_top_tracks_by_play_count` query.
pub async fn query(
    client: &Client,
    params: &GetTopTracksByPlayCountParams,
) -> Result<GetTopTracksByPlayCountResult, tokio_postgres::Error> {
    let rows = client.query(SQL, &[&params.limit as &(dyn postgres_types::ToSql + Sync)]).await?;
    Ok(rows.into_iter().map(|row| row.into()).collect())
}
