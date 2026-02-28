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
        let packageName =
              Deps.CodegenKit.Name.concat input.space [ input.name ]

        let packageName = Deps.CodegenKit.Name.toTextInKebab packageName

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

        let queryFiles
            : List Sdk.File.Type
            = Deps.Prelude.List.map
                QueryGen.Output
                Sdk.File.Type
                ( \(query : QueryGen.Output) ->
                    { path = query.modulePath
                    , content = query.moduleContents
                    }
                )
                queries

        let cargoToml =
              { path = "Cargo.toml"
              , content =
                  Templates.CargoToml.run
                    { packageName
                    , version = "0.1.0"
                    , dbName = Deps.CodegenKit.Name.toTextInSnake input.name
                    }
              }

        let libRs =
              { path = "src/lib.rs"
              , content = Templates.LibRs.run {=}
              }

        let typesModRs
            : Sdk.File.Type
            = { path = "src/types/mod.rs"
              , content =
                  Templates.TypesModRs.run
                    { modules =
                        Deps.Prelude.List.map
                          CustomTypeGen.Output
                          Text
                          ( \(customType : CustomTypeGen.Output) ->
                              customType.moduleName
                          )
                          customTypes
                    }
              }

        let queriesModRs
            : Sdk.File.Type
            = { path = "src/queries/mod.rs"
              , content =
                  Templates.QueriesModRs.run
                    { modules =
                        Deps.Prelude.List.map
                          QueryGen.Output
                          Text
                          ( \(query : QueryGen.Output) ->
                              query.moduleName
                          )
                          queries
                    }
              }

        in      [ cargoToml
                , libRs
                , typesModRs
                , queriesModRs
                ]
              # customTypeFiles
              # queryFiles
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
