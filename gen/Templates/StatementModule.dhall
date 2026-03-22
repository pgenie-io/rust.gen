let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let Params =
      { queryName : Text
      , typeName : Text
      , srcPath : Text
      , sqlDocLines : Text
      , hasParams : Bool
      , paramFields : Text
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
                      /// # SQL Template
                      ///
                      /// ```sql
                      ${params.sqlDocLines}
                      /// ```
                      ///
                      /// # Source Path
                      ///
                      /// `${params.srcPath}`
                      #[derive(Debug, Clone, PartialEq, Default)]
                      pub struct Input;
                      ''
                else  ''
                      /// Parameters for the `${params.queryName}` query.
                      ///
                      /// # SQL Template
                      ///
                      /// ```sql
                      ${params.sqlDocLines}
                      /// ```
                      ///
                      /// # Source Path
                      ///
                      /// `${params.srcPath}`
                      #[derive(Debug, Clone, PartialEq, Default)]
                      pub struct Input {
                      ${params.paramFields}
                      }
                      ''

          in  ''
              use tokio_postgres::types::Type;

              ${paramsSection}
              ${params.typeDecls}
              ${params.statementImpl}
              ''
      )
