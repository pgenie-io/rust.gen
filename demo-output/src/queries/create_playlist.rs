//! Query module for `create_playlist`.
//!
//! SQL:
//! ```sql
//! INSERT INTO playlist (name, description, user_id)
//! VALUES ($name, $description, $user_id)
//! RETURNING id, name, created_at
//! ```
//!
//! Source: `queries/create_playlist.sql`

use tokio_postgres::Client;

/// Parameters for the `create_playlist` query.
#[derive(Debug, Clone)]
pub struct CreatePlaylistParams {
    /// Maps to `name`.
    pub name: String,
    /// Maps to `description`.
    pub description: Option<String>,
    /// Maps to `user_id`.
    pub user_id: uuid::Uuid,
}

/// Result of the `CreatePlaylist` query.
pub type CreatePlaylistResult = Vec<CreatePlaylistResultRow>;

/// Row of [`CreatePlaylistResult`].
#[derive(Debug, Clone)]
pub struct CreatePlaylistResultRow {
    /// Maps to `id`.
    pub id: uuid::Uuid,
    /// Maps to `name`.
    pub name: String,
    /// Maps to `created_at`.
    pub created_at: chrono::NaiveDateTime,
}

impl From<tokio_postgres::Row> for CreatePlaylistResultRow {
    fn from(row: tokio_postgres::Row) -> Self {
        Self {
            id: row.get("id"),
            name: row.get("name"),
            created_at: row.get("created_at"),
        }
    }
}

/// SQL query string.
pub const SQL: &str = "INSERT INTO playlist (name, description, user_id)\nVALUES ($1, $2, $3)\nRETURNING id, name, created_at";

/// Execute the `create_playlist` query.
pub async fn query(
    client: &Client,
    params: &CreatePlaylistParams,
) -> Result<CreatePlaylistResult, tokio_postgres::Error> {
    let rows = client.query(SQL, &[&params.name as &(dyn postgres_types::ToSql + Sync), &params.description as &(dyn postgres_types::ToSql + Sync), &params.user_id as &(dyn postgres_types::ToSql + Sync)]).await?;
    Ok(rows.into_iter().map(|row| row.into()).collect())
}
