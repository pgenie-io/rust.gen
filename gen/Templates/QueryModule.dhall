let Deps = ../Deps/package.dhall

let Input =
      { moduleName : Text
      , structName : Text
      , srcPath : Text
      , sqlExp : Text
      , sqlDocComment : Text
      , typeDecls : Text
      , queryBody : Text
      , paramFields : List Text
      }

let run =
      \(input : Input) ->
        let resultTypeName = "${input.structName}Result"

        let paramsDecl =
              if    Deps.Prelude.List.null Text input.paramFields
              then  ""
              else  ''

                    /// Parameters for the `${input.moduleName}` query.
                    #[derive(Debug, Clone)]
                    pub struct ${input.structName}Params {
                    ${Deps.Prelude.Text.concatMap
                        Text
                        (\(field : Text) -> field ++ "\n")
                        input.paramFields}}
                    ''

        let fnParams =
              if    Deps.Prelude.List.null Text input.paramFields
              then  ""
              else  ''

                    ${"    "}params: &${input.structName}Params,''

        in  ''
            //! Query module for `${input.moduleName}`.
            //!
            //! SQL:
            //! ```sql
            //! ${input.sqlDocComment}
            //! ```
            //!
            //! Source: `${input.srcPath}`

            use tokio_postgres::Client;
            ${paramsDecl}
            ${input.typeDecls}
            /// SQL query string.
            pub const SQL: &str = ${input.sqlExp};

            /// Execute the `${input.moduleName}` query.
            pub async fn query(
                client: &Client,${fnParams}
            ) -> Result<${resultTypeName}, tokio_postgres::Error> {
                ${input.queryBody}
            }
            ''

in  { Input, run }
