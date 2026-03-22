use chrono::NaiveDate;
use tokio_postgres::types::Type;

use crate::types::{AlbumFormat, RecordingInfo};

/// Parameters for the `update_album_recording_returning` query.
///
/// # SQL Template
///
/// ```sql
/// -- Update album recording information
/// update album
/// set recording = $recording
/// where id = $id
/// returning *
/// ```
///
/// # Source Path
///
/// `./queries/update_album_recording_returning.sql`
#[derive(Debug, Clone, PartialEq, Default)]
pub struct Input {
    /// Maps to `$recording` in the template.
    pub recording: Option<RecordingInfo>,
    /// Maps to `$id` in the template.
    pub id: Option<i64>,
}

/// Result of the statement parameterised by [`Input`].
pub type Output = Vec<OutputRow>;

/// Row of [`Output`].
#[derive(Debug, Clone, PartialEq)]
pub struct OutputRow {
    /// Maps to the `id` result set column.
    pub id: i64,
    /// Maps to the `name` result set column.
    pub name: String,
    /// Maps to the `released` result set column.
    pub released: Option<NaiveDate>,
    /// Maps to the `format` result set column.
    pub format: Option<AlbumFormat>,
    /// Maps to the `recording` result set column.
    pub recording: Option<RecordingInfo>,
}

impl crate::mapping::Statement for Input {
    type Result = Output;

    const RETURNS_ROWS: bool = true;

    const SQL: &str = "-- Update album recording information\n\
                       update album\n\
                       set recording = $1::recording_info\n\
                       where id = $2\n\
                       returning *";

    const PARAM_TYPES: &'static [tokio_postgres::types::Type] = &[Type::UNKNOWN, Type::INT8];

    #[allow(refining_impl_trait)]
    fn encode_params(
        &self,
    ) -> [&(dyn tokio_postgres::types::ToSql + Sync); Self::PARAM_TYPES.len()] {
        [&self.recording, &self.id]
    }

    fn decode_result(
        rows: Vec<tokio_postgres::Row>,
        _affected_rows: u64,
    ) -> Result<Self::Result, crate::mapping::DecodingError> {
        rows.into_iter()
            .enumerate()
            .map(|(row_index, row)| {
                Ok(OutputRow {
                    id: crate::mapping::decode_cell(&row, row_index, 0)?,
                    name: crate::mapping::decode_cell(&row, row_index, 1)?,
                    released: crate::mapping::decode_cell(&row, row_index, 2)?,
                    format: crate::mapping::decode_cell(&row, row_index, 3)?,
                    recording: crate::mapping::decode_cell(&row, row_index, 4)?,
                })
            })
            .collect()
    }
}
