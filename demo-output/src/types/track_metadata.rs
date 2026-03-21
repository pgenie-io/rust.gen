//! Representation of the `track_metadata` PostgreSQL composite type.

use postgres_types::{FromSql, ToSql};

/// Representation of the `track_metadata` user-declared PostgreSQL composite type
/// from the `music_catalogue` schema.
#[derive(Debug, Clone, PartialEq, FromSql, ToSql)]
#[postgres(name = "track_metadata")]
pub struct TrackMetadata {
    /// Maps to `title`.
    pub title: String,
    /// Maps to `metadata`.
    pub metadata: Option<Vec<Option<serde_json::Value>>>,
    /// Maps to `created_at`.
    pub created_at: chrono::NaiveDateTime,
}
