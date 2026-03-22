let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let Params =
      { queryName : Text
      , typeName : Text
      , srcPath : Text
      , sqlDocLines : Text
      , sqlExp : Text
      , paramFields : Text
      , paramExprs : Text
      , typeDecls : Text
      , decodeBody : Text
      , decoderBlock : Text
      }

in  Algebra.module
      Params
      ( \(params : Params) ->
          let paramsSection =
                if    Deps.Prelude.Text.null params.paramFields
                then  ''
                      /// Parameters for the `${params.queryName}` query.
                      ///
                      /// # SQL
                      ///
                      ${params.sqlDocLines}
                      ///
                      /// # Source
                      ///
                      /// `${params.srcPath}`
                      #[derive(Debug, Clone)]
                      pub struct Input;

                      impl Input {
                          pub fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
                              vec![]
                          }
                      }
                      ''
                else  ''
                      /// Parameters for the `${params.queryName}` query.
                      ///
                      /// # SQL
                      ///
                      ${params.sqlDocLines}
                      ///
                      /// # Source
                      ///
                      /// `${params.srcPath}`
                      #[derive(Debug, Clone)]
                      pub struct Input {
                      ${params.paramFields}
                      }

                      impl Input {
                          pub fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
                              vec![${params.paramExprs}]
                          }
                      }
                      ''

          let decodeImpl =
                merge
                  { rows_affected =
                      ''
                      impl crate::Statement for Input {
                          type Output = Output;

                          fn sql() -> &'static str {
                              SQL
                          }

                          fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
                              self.params()
                          }

                          fn decode(_rows: Vec<tokio_postgres::Row>, rows_affected: u64) -> Self::Output {
                              rows_affected
                          }
                      }
                      ''
                  , optional =
                      ''
                      impl crate::Statement for Input {
                          type Output = Output;

                          fn sql() -> &'static str {
                              SQL
                          }

                          fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
                              self.params()
                          }

                          fn decode(rows: Vec<tokio_postgres::Row>, _rows_affected: u64) -> Self::Output {
                              rows.into_iter().next().map(|row| OutputRow::from_row(&row))
                          }
                      }
                      ''
                  , single =
                      ''
                      impl crate::Statement for Input {
                          type Output = Output;

                          fn sql() -> &'static str {
                              SQL
                          }

                          fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
                              self.params()
                          }

                          fn decode(rows: Vec<tokio_postgres::Row>, _rows_affected: u64) -> Self::Output {
                              let row = rows.into_iter().next().expect("expected exactly one row");
                              OutputRow::from_row(&row)
                          }
                      }
                      ''
                  , multiple =
                      ''
                      impl crate::Statement for Input {
                          type Output = Output;

                          fn sql() -> &'static str {
                              SQL
                          }

                          fn params(&self) -> Vec<&(dyn postgres_types::ToSql + Sync)> {
                              self.params()
                          }

                          fn decode(rows: Vec<tokio_postgres::Row>, _rows_affected: u64) -> Self::Output {
                              rows.iter().map(|row| OutputRow::from_row(row)).collect()
                          }
                      }
                      ''
                  }
                  params.decoderBlock

          in  ''
              use postgres_types::ToSql;

              /// SQL query string.
              pub const SQL: &str = ${params.sqlExp};

              ${paramsSection}
              ${params.typeDecls}
              ${decodeImpl}
              ''
      )
