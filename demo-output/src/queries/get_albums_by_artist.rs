//! Query module for `get_albums_by_artist`.
//!
//! SQL:
//! ```sql
//! SELECT id, name, released_year, album_type, created_at
//! FROM album
//! WHERE artist_id = $artist_id
//! ```
//!
//! Source: `queries/get_albums_by_artist.sql`

use tokio_postgres::Client;

/// Parameters for the `get_albums_by_artist` query.
#[derive(Debug, Clone)]
pub struct GetAlbumsByArtistParams {
    /// Maps to `artist_id`.
    pub artist_id: uuid::Uuid,
}

/// Result of the `GetAlbumsByArtist` query.
pub type GetAlbumsByArtistResult = Vec<GetAlbumsByArtistResultRow>;

/// Row of [`GetAlbumsByArtistResult`].
#[derive(Debug, Clone)]
pub struct GetAlbumsByArtistResultRow {
    /// Maps to `id`.
    pub id: uuid::Uuid,
    /// Maps to `name`.
    pub name: String,
    /// Maps to `released_year`.
    pub released_year: Option<i32>,
    /// Maps to `album_type`.
    pub album_type: crate::types::AlbumType,
    /// Maps to `created_at`.
    pub created_at: chrono::NaiveDateTime,
}

impl From<tokio_postgres::Row> for GetAlbumsByArtistResultRow {
    fn from(row: tokio_postgres::Row) -> Self {
        Self {
            id: row.get("id"),
            name: row.get("name"),
            released_year: row.get("released_year"),
            album_type: row.get("album_type"),
            created_at: row.get("created_at"),
        }
    }
}

/// SQL query string.
pub const SQL: &str = "SELECT id, name, released_year, album_type, created_at\nFROM album\nWHERE artist_id = $1";

/// Execute the `get_albums_by_artist` query.
pub async fn query(
    client: &Client,
    params: &GetAlbumsByArtistParams,
) -> Result<GetAlbumsByArtistResult, tokio_postgres::Error> {
    let rows = client.query(SQL, &[&params.artist_id as &(dyn postgres_types::ToSql + Sync)]).await?;
    Ok(rows.into_iter().map(|row| row.into()).collect())
}
