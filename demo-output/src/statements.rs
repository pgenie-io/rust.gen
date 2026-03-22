//! Mappings to all queries in the project.
//!
//! Each sub-module exposes a parameter struct that implements [`crate::mapping::Statement`].
//! Call [`crate::mapping::Statement::execute`] with a [`tokio_postgres::Client`] to run
//! the query and receive the corresponding result type.

pub mod insert_album;
pub mod select_album_by_format;
pub mod select_genre_by_artist;
pub mod update_album_recording_returning;
pub mod update_album_released;
