//! Representation of the `album_type` PostgreSQL enumeration type.

use postgres_types::{FromSql, ToSql};

/// Representation of the `album_type` user-declared PostgreSQL enumeration type
/// from the `music_catalogue` schema.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, ToSql, FromSql)]
#[postgres(name = "album_type")]
pub enum AlbumType {
    /// Corresponds to the PostgreSQL enum variant `studio`.
    #[postgres(name = "studio")]
    Studio,
    /// Corresponds to the PostgreSQL enum variant `live`.
    #[postgres(name = "live")]
    Live,
    /// Corresponds to the PostgreSQL enum variant `compilation`.
    #[postgres(name = "compilation")]
    Compilation,
    /// Corresponds to the PostgreSQL enum variant `soundtrack`.
    #[postgres(name = "soundtrack")]
    Soundtrack,
    /// Corresponds to the PostgreSQL enum variant `ep`.
    #[postgres(name = "ep")]
    Ep,
    /// Corresponds to the PostgreSQL enum variant `single`.
    #[postgres(name = "single")]
    Single,
}
