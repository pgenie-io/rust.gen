let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Member = ./Member.dhall

let Input = Deps.Sdk.Project.ResultRows

let Output = Text -> { typeDecls : Text, queryBody : Text -> Text }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        let compiledColumns =
              Deps.Typeclasses.Classes.Applicative.traverseList
                Deps.Sdk.Compiled.Type
                Deps.Sdk.Compiled.applicative
                Deps.Sdk.Project.Member
                Member.Output
                (Member.run config)
                ( Deps.Prelude.NonEmpty.toList
                    Deps.Sdk.Project.Member
                    input.columns
                )

        in  Deps.Sdk.Compiled.flatMap
              (List Member.Output)
              Output
              ( \(columns : List Member.Output) ->
                  Deps.Sdk.Compiled.ok
                    Output
                    ( \(typeNameBase : Text) ->
                        let rowTypeName = "${typeNameBase}ResultRow"

                        let columnFields =
                              Deps.Prelude.Text.concatMap
                                Member.Output
                                ( \(column : Member.Output) ->
                                    column.fieldDeclaration ++ "\n"
                                )
                                columns

                        let columnGetters =
                              Deps.Prelude.Text.concatMap
                                Member.Output
                                ( \(column : Member.Output) ->
                                    "            ${column.fieldName}: row.get(\"${column.fieldName}\"),\n"
                                )
                                columns

                        let rowTypeDecl =
                              ''
                              /// Row of [`${typeNameBase}Result`].
                              #[derive(Debug, Clone)]
                              pub struct ${rowTypeName} {
                              ${columnFields}}

                              impl From<tokio_postgres::Row> for ${rowTypeName} {
                                  fn from(row: tokio_postgres::Row) -> Self {
                                      Self {
                              ${columnGetters}        }
                                  }
                              }
                              ''

                        let resolvedCardinality =
                              merge
                                { Optional =
                                  { queryBody =
                                      \(paramsExp : Text) ->
                                        ''
                                        let row = client.query_opt(SQL, &[${paramsExp}]).await?;
                                            Ok(row.map(|row| row.into()))''
                                  , resultTypeDecl =
                                      "pub type ${typeNameBase}Result = Option<${rowTypeName}>;"
                                  }
                                , Single =
                                  { queryBody =
                                      \(paramsExp : Text) ->
                                        ''
                                        let row = client.query_one(SQL, &[${paramsExp}]).await?;
                                            Ok(row.into())''
                                  , resultTypeDecl =
                                      "pub type ${typeNameBase}Result = ${rowTypeName};"
                                  }
                                , Multiple =
                                  { queryBody =
                                      \(paramsExp : Text) ->
                                        ''
                                        let rows = client.query(SQL, &[${paramsExp}]).await?;
                                            Ok(rows.into_iter().map(|row| row.into()).collect())''
                                  , resultTypeDecl =
                                      "pub type ${typeNameBase}Result = Vec<${rowTypeName}>;"
                                  }
                                }
                                input.cardinality

                        let typeDecls =
                              ''
                              /// Result of the `${typeNameBase}` query.
                              ${resolvedCardinality.resultTypeDecl}

                              ${rowTypeDecl}''

                        in  { queryBody = resolvedCardinality.queryBody
                            , typeDecls
                            }
                    )
              )
              compiledColumns

in  Algebra.module Input Output run
