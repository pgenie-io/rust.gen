let Sdk = ../Deps/Sdk.dhall

let Lude = ../Deps/Lude.dhall

let Params =
      { queryName : Text
      , typeName : Text
      , srcPath : Text
      , sqlDocLines : Text
      , hasParams : Bool
      , canDeriveDefault : Bool
      , paramFields : Text
      , typeDecls : Text
      , statementImpl : Text
      }

in  Sdk.Sigs.template
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
                      #[derive(Debug, Clone, PartialEq${if    params.canDeriveDefault
                                                        then  ", Default"
                                                        else  ""})]
                      pub struct Input {
                          ${Lude.Text.indentNonEmpty 4 params.paramFields}
                      }
                      ''

          in  ''
              use tokio_postgres::types::Type;

              ${paramsSection}
              ${params.typeDecls}
              ${params.statementImpl}
              ''
      )
