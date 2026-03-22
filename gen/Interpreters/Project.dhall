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

        let typesModRs
            : Sdk.File.Type
            = { path = "src/types/mod.rs"
              , content =
                  ''
                  ${typeModNames}
                  ''
              }

        let statementsModRs
            : Sdk.File.Type
            = { path = "src/statements/mod.rs"
              , content =
                  ''
                  ${stmtModNames}
                  ''
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

        in      [ cargoToml, libRs, typesModRs, statementsModRs ]
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
