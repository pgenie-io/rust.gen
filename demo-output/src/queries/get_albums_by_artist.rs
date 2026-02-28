//! Query module for `get_albums_by_artist`.
//!
//! SQL:
//! ```sql
//! SELECT 
//!     a.id,
//!     a.title,
//!     a.release_year,
//!     a.album_type
//! FROM albums a
//! WHERE a.artist_id = $artist_id ORDER BY a.release_year DESC
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
    /// Maps to `title`.
    pub title: String,
    /// Maps to `release_year`.
    pub release_year: Option<i32>,
    /// Maps to `album_type`.
    pub album_type: crate::types::AlbumType,
}

impl From<tokio_postgres::Row> for GetAlbumsByArtistResultRow {
    fn from(row: tokio_postgres::Row) -> Self {
        Self {
            id: row.get("id"),
            title: row.get("title"),
            release_year: row.get("release_year"),
            album_type: row.get("album_type"),
        }
    }
}

/// SQL query string.
pub const SQL: &str = "SELECT \n    a.id,\n    a.title,\n    a.release_year,\n    a.album_type\nFROM albums a\nWHERE a.artist_id = $1 ORDER BY a.release_year DESC";

/// Execute the `get_albums_by_artist` query.
pub async fn query(
    client: &Client,
    params: &GetAlbumsByArtistParams,
) -> Result<GetAlbumsByArtistResult, tokio_postgres::Error> {
    let rows = client.query(SQL, &[&params.artist_id as &(dyn postgres_types::ToSql + Sync)]).await?;
    Ok(rows.into_iter().map(|row| row.into()).collect())
}
