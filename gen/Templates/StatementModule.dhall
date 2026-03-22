let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let Params =
      { queryName : Text
      , typeName : Text
      , srcPath : Text
      , sqlDocLines : Text
      , sqlExp : Text
      , hasParams : Bool
      , paramFields : Text
      , paramExprs : Text
      , typeDecls : Text
      , statementImpl : Text
      }

in  Algebra.module
      Params
      ( \(params : Params) ->
          let paramsSection =
                if    params.hasParams == False
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

          in  ''
              use postgres_types::ToSql;

              /// SQL query string.
              pub const SQL: &str = ${params.sqlExp};

              ${paramsSection}
              ${params.typeDecls}
              ${params.statementImpl}
              ''
      )
