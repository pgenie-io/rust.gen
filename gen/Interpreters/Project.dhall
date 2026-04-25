let Deps = ../Deps/package.dhall

let Algebra = ../Algebras/package.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Templates = ../Templates/package.dhall

let QueryGen = ./Query.dhall

let CustomTypeGen = ./CustomType.dhall

let Input = Model.Project

let Output = List Sdk.File.Type

let combineOutputs =
      \(config : Algebra.Interpreter.Config) ->
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

        let migrationFiles
            : List Sdk.File.Type
            = Deps.Prelude.List.map
                { name : Text, sql : Text }
                Sdk.File.Type
                ( \(migration : { name : Text, sql : Text }) ->
                    { path = "migrations/${migration.name}.sql"
                    , content = migration.sql
                    }
                )
                input.migrations

        let typeModNames =
              Deps.Prelude.Text.concatMapSep
                "\n"
                CustomTypeGen.Output
                ( \(customType : CustomTypeGen.Output) ->
                    "mod ${customType.moduleName};"
                )
                customTypes

        let typeReexports =
              Deps.Prelude.Text.concatMapSep
                "\n"
                CustomTypeGen.Output
                ( \(customType : CustomTypeGen.Output) ->
                    "pub use ${customType.moduleName}::${customType.typeName};"
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
              , content =
                  Templates.LibRs.run { rootModuleName = config.rootModuleName }
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
                    , deadpool = config.deadpool
                    }
              }

        let mappingModRs
            : Sdk.File.Type
            = { path = "src/mapping.rs"
              , content =
                  Templates.MappingModule.run { deadpool = config.deadpool }
              }

        let decodingErrorRs =
              { path = "src/mapping/decoding_error.rs"
              , content = Templates.DecodingErrorModule.run {=}
              }

        let deadpoolFiles
            : List Sdk.File.Type
            = if    config.deadpool
              then  [ { path = "src/mapping/error.rs"
                      , content = Templates.MappingErrorModule.run {=}
                      }
                    ]
              else  [] : List Sdk.File.Type

        let statementsRs
            : Sdk.File.Type
            = { path = "src/statements.rs"
              , content = Templates.StatementsModule.run { stmtModNames }
              }

        let typesRs
            : Sdk.File.Type
            = { path = "src/types.rs"
              , content =
                  Templates.TypesModule.run { typeModNames, typeReexports }
              }

        let crateName =
              Deps.CodegenKit.Name.toTextInSnake
                (Deps.CodegenKit.Name.concat input.space [ input.name ])

        let stmtAsserts =
              Deps.Prelude.Text.concatMapSep
                "\n"
                QueryGen.Output
                ( \(query : QueryGen.Output) ->
                    "    assert_statement_executes::<statements::${query.statementModuleName}::Input>(&pool, \"${query.statementModuleName}\").await;"
                )
                queries

        let migrationEntries
            : Text
            = Deps.Prelude.Text.concatMapSep
                "\n"
                { name : Text, sql : Text }
                ( \(migration : { name : Text, sql : Text }) ->
                    "        (\"${migration.name}.sql\", include_str!(\"../migrations/${migration.name}.sql\")),"
                )
                input.migrations

        let testsRs
            : Sdk.File.Type
            = { path = "tests/tests.rs"
              , content =
                  Templates.TestsModule.run
                    { crateName, migrationEntries, stmtAsserts }
              }

        in      [ cargoToml
                , libRs
                , mappingModRs
                , decodingErrorRs
                , typesRs
                , statementsRs
                , testsRs
                ]
              # deadpoolFiles
              # migrationFiles
              # customTypeFiles
              # statementFiles
            : List Sdk.File.Type

let run =
      \(config : Algebra.Interpreter.Config) ->
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

in  Algebra.Interpreter.module Input Output run
