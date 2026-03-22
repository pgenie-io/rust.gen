let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Templates = ../Templates/package.dhall

let QueryGen = ./Query.dhall

let CustomTypeGen = ./CustomType.dhall

let Input = Model.Project

let Output = List Sdk.File.Type

let combineOutputs =
      \(config : Algebra.Config) ->
      \(input : Input) ->
      \(queries : List QueryGen.Output) ->
      \(customTypes : List CustomTypeGen.Output) ->
        let customTypeFiles
            : List Sdk.File.Type
            = Deps.Prelude.List.map
                CustomTypeGen.Output
                Sdk.File.Type
                ( \(customType : CustomTypeGen.Output) ->
                    { path = customType.modulePath
                    , content = customType.moduleContent
                    }
                )
                customTypes

        let statementFiles
            : List Sdk.File.Type
            = Deps.Prelude.List.map
                QueryGen.Output
                Sdk.File.Type
                ( \(query : QueryGen.Output) ->
                    { path = query.statementModulePath
                    , content = query.statementModuleContents
                    }
                )
                queries

        let typeModNames =
              Deps.Prelude.Text.concatMapSep
                "\n"
                CustomTypeGen.Output
                ( \(customType : CustomTypeGen.Output) ->
                    "pub mod ${customType.moduleName};"
                )
                customTypes

        let stmtModNames =
              Deps.Prelude.Text.concatMapSep
                "\n"
                QueryGen.Output
                ( \(query : QueryGen.Output) ->
                    "pub mod ${query.statementModuleName};"
                )
                queries

        let libRs
            : Sdk.File.Type
            = { path = "src/lib.rs"
              , content = Templates.LibRs.run { rootModuleName = config.rootModuleName }
              }

        let packageName =
              Deps.CodegenKit.Name.toTextInKebab
                (Deps.CodegenKit.Name.concat input.space [ input.name ])

        let cargoToml
            : Sdk.File.Type
            = { path = "Cargo.toml"
              , content =
                  Templates.CargoToml.run
                    { packageName
                    , version =
                            Natural/show input.version.major
                        ++  "."
                        ++  Natural/show input.version.minor
                        ++  "."
                        ++  Natural/show input.version.patch
                    , dbName = Deps.CodegenKit.Name.toTextInSnake input.name
                    }
              }

        let mappingModRs
            : Sdk.File.Type
            = { path = "src/mapping/mod.rs"
              , content =
                  ''
                  //! Shared PostgreSQL statement mapping primitives.

                  mod decoding_error;
                  pub use decoding_error::{decode_cell, DecodingError};

                  /// Implemented by each query's parameter struct. Provides a uniform way to
                  /// prepare and execute statements against a [`tokio_postgres::Client`].
                  pub trait Statement {
                      /// The type returned when the statement is successfully executed.
                      type Result;

                      const SQL: &str;

                      const PARAM_TYPES: &'static [tokio_postgres::types::Type];

                      /// Encode `self` as a list of type-erased parameter references.
                      fn encode_params(&self) -> impl AsRef<[&(dyn tokio_postgres::types::ToSql + Sync)]>;

                      /// Whether the statement returns rows.
                      const RETURNS_ROWS: bool;

                      fn decode_result(
                          rows: Vec<tokio_postgres::Row>,
                          affected_rows: u64,
                      ) -> Result<Self::Result, DecodingError>;
                  }
                  ''
              }

        let decodingErrorRs
            : Sdk.File.Type
            = { path = "src/mapping/decoding_error.rs"
              , content =
                  ''
                  use tokio_postgres::{types::FromSql, Row};

                  #[derive(Debug)]
                  pub enum DecodingError {
                      UnexpectedAmountOfRows {
                          expected: usize,
                          actual: usize,
                      },
                      Cell {
                          row: usize,
                          column: usize,
                          source: tokio_postgres::Error,
                      },
                  }

                  impl std::fmt::Display for DecodingError {
                      fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                          match self {
                              DecodingError::UnexpectedAmountOfRows { expected, actual } => {
                                  write!(f, "expected {expected} row(s), got {actual}")
                              }
                              DecodingError::Cell {
                                  row,
                                  column,
                                  source: error,
                              } => {
                                  write!(f, "error at row {row}, column {column}: {error}")
                              }
                          }
                      }
                  }

                  impl std::error::Error for DecodingError {
                      fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
                          match self {
                              DecodingError::Cell { source: error, .. } => Some(error),
                              DecodingError::UnexpectedAmountOfRows { .. } => None,
                          }
                      }
                  }

                  /// Decode a single result-set cell and attach its row/column location to any
                  /// PostgreSQL decoding error.
                  pub fn decode_cell<'a, T: FromSql<'a>>(
                      input_row: &'a Row,
                      row_index: usize,
                      column_index: usize,
                  ) -> Result<T, DecodingError> {
                      input_row
                          .try_get(column_index)
                          .map_err(|source| DecodingError::Cell {
                              row: row_index,
                              column: column_index,
                              source,
                          })
                  }
                  ''
              }

        let statementsRs
            : Sdk.File.Type
            = { path = "src/statements.rs"
              , content =
                  ''
                  //! Mappings to all queries in the project.
                  //!
                  //! Each sub-module exposes a parameter struct that implements [`crate::mapping::Statement`].

                  ${stmtModNames}
                  ''
              }

        let typesRs
            : Sdk.File.Type
            = { path = "src/types.rs"
              , content =
                  ''
                  ${typeModNames}
                  ''
              }

        in      [ cargoToml, libRs, mappingModRs, decodingErrorRs, typesRs, statementsRs ]
              # customTypeFiles
              # statementFiles
            : List Sdk.File.Type

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        let compiledQueries
            : Sdk.Compiled.Type (List (Optional QueryGen.Output))
            = Sdk.Compiled.traverseList
                Deps.Sdk.Project.Query
                (Optional QueryGen.Output)
                ( \(query : Deps.Sdk.Project.Query) ->
                    Deps.Typeclasses.Classes.Alternative.optional
                      Sdk.Compiled.Type
                      Sdk.Compiled.alternative
                      QueryGen.Output
                      (QueryGen.run config query)
                )
                input.queries

        let compiledQueries
            : Sdk.Compiled.Type (List QueryGen.Output)
            = Sdk.Compiled.map
                (List (Optional QueryGen.Output))
                (List QueryGen.Output)
                (Deps.Prelude.List.unpackOptionals QueryGen.Output)
                compiledQueries

        let compiledTypes
            : Sdk.Compiled.Type (List CustomTypeGen.Output)
            = Sdk.Compiled.traverseList
                Deps.Sdk.Project.CustomType
                CustomTypeGen.Output
                (CustomTypeGen.run config)
                input.customTypes

        let files
            : Sdk.Compiled.Type (List Sdk.File.Type)
            = Sdk.Compiled.map2
                (List QueryGen.Output)
                (List CustomTypeGen.Output)
                (List Sdk.File.Type)
                (combineOutputs config input)
                compiledQueries
                compiledTypes

        in  files

in  Algebra.module Input Output run
