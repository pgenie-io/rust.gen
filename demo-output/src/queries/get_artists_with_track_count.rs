//! Query module for `get_artists_with_track_count`.
//!
//! SQL:
//! ```sql
//! SELECT 
//!     ar.id,
//!     ar.name,
//!     COUNT(t.id) as track_count
//! FROM artists ar
//! LEFT JOIN albums a ON ar.id = a.artist_id
//! LEFT JOIN tracks t ON a.id = t.album_id
//! GROUP BY ar.id, ar.name
//! ORDER BY track_count DESC
//! ```
//!
//! Source: `queries/get_artists_with_track_count.sql`

use tokio_postgres::Client;

/// Result of the `GetArtistsWithTrackCount` query.
pub type GetArtistsWithTrackCountResult = Vec<GetArtistsWithTrackCountResultRow>;

/// Row of [`GetArtistsWithTrackCountResult`].
#[derive(Debug, Clone)]
pub struct GetArtistsWithTrackCountResultRow {
    /// Maps to `id`.
    pub id: uuid::Uuid,
    /// Maps to `name`.
    pub name: String,
    /// Maps to `track_count`.
    pub track_count: i64,
}

impl From<tokio_postgres::Row> for GetArtistsWithTrackCountResultRow {
    fn from(row: tokio_postgres::Row) -> Self {
        Self {
            id: row.get("id"),
            name: row.get("name"),
            track_count: row.get("track_count"),
        }
    }
}

/// SQL query string.
pub const SQL: &str = "SELECT \n    ar.id,\n    ar.name,\n    COUNT(t.id) as track_count\nFROM artists ar\nLEFT JOIN albums a ON ar.id = a.artist_id\nLEFT JOIN tracks t ON a.id = t.album_id\nGROUP BY ar.id, ar.name\nORDER BY track_count DESC";

/// Execute the `get_artists_with_track_count` query.
pub async fn query(
    client: &Client,
) -> Result<GetArtistsWithTrackCountResult, tokio_postgres::Error> {
    let rows = client.query(SQL, &[]).await?;
    Ok(rows.into_iter().map(|row| row.into()).collect())
}
