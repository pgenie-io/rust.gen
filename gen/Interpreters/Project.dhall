let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Typeclasses = ../Deps/Typeclasses.dhall

let Project = ../Deps/Project.dhall

let Templates = ../Templates/package.dhall

let QueryGen = ./Query.dhall

let CustomTypeGen = ./CustomType.dhall

let Input = Project.Project

let Output = List Lude.File.Type

let combineOutputs =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
      \(queries : List QueryGen.Output) ->
      \(customTypes : List CustomTypeGen.Output) ->
        let customTypeFiles
            : List Lude.File.Type
            = Prelude.List.map
                CustomTypeGen.Output
                Lude.File.Type
                ( \(customType : CustomTypeGen.Output) ->
                    { path = customType.modulePath
                    , content = customType.moduleContent
                    }
                )
                customTypes

        let statementFiles
            : List Lude.File.Type
            = Prelude.List.map
                QueryGen.Output
                Lude.File.Type
                ( \(query : QueryGen.Output) ->
                    { path = query.statementModulePath
                    , content = query.statementModuleContents
                    }
                )
                queries

        let migrationFiles
            : List Lude.File.Type
            = Prelude.List.map
                { name : Text, sql : Text }
                Lude.File.Type
                ( \(migration : { name : Text, sql : Text }) ->
                    { path = "migrations/${migration.name}.sql"
                    , content = migration.sql
                    }
                )
                input.migrations

        let typeModNames =
              Prelude.Text.concatMapSep
                "\n"
                CustomTypeGen.Output
                ( \(customType : CustomTypeGen.Output) ->
                    "mod ${customType.moduleName};"
                )
                customTypes

        let typeReexports =
              Prelude.Text.concatMapSep
                "\n"
                CustomTypeGen.Output
                ( \(customType : CustomTypeGen.Output) ->
                    "pub use ${customType.moduleName}::${customType.typeName};"
                )
                customTypes

        let stmtModNames =
              Prelude.Text.concatMapSep
                "\n"
                QueryGen.Output
                ( \(query : QueryGen.Output) ->
                    "pub mod ${query.statementModuleName};"
                )
                queries

        let libRs
            : Lude.File.Type
            = { path = "src/lib.rs"
              , content =
                  Templates.LibRs.run { rootModuleName = config.rootModuleName }
              }

        let packageName =
              Lude.Name.toTextInKebab
                (Lude.Name.concat input.space [ input.name ])

        let cargoToml
            : Lude.File.Type
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
                    , dbName = Lude.Name.toTextInSnake input.name
                    , deadpool = config.deadpool
                    }
              }

        let mappingModRs
            : Lude.File.Type
            = { path = "src/mapping.rs"
              , content =
                  Templates.MappingModule.run { deadpool = config.deadpool }
              }

        let decodingErrorRs =
              { path = "src/mapping/decoding_error.rs"
              , content = Templates.DecodingErrorModule.run {=}
              }

        let deadpoolFiles
            : List Lude.File.Type
            = if    config.deadpool
              then  [ { path = "src/mapping/error.rs"
                      , content = Templates.MappingErrorModule.run {=}
                      }
                    ]
              else  [] : List Lude.File.Type

        let statementsRs
            : Lude.File.Type
            = { path = "src/statements.rs"
              , content = Templates.StatementsModule.run { stmtModNames }
              }

        let typesRs
            : Lude.File.Type
            = { path = "src/types.rs"
              , content =
                  Templates.TypesModule.run { typeModNames, typeReexports }
              }

        let crateName =
              Lude.Name.toTextInSnake
                (Lude.Name.concat input.space [ input.name ])

        let stmtAsserts =
              Prelude.Text.concatMapSep
                "\n"
                QueryGen.Output
                ( \(query : QueryGen.Output) ->
                    if    query.canDeriveDefault
                    then  "    assert_statement_executes::<statements::${query.statementModuleName}::Input>(&pool, \"${query.statementModuleName}\").await;"
                    else  ""
                )
                queries

        let migrationEntries
            : Text
            = Prelude.Text.concatMapSep
                "\n"
                { name : Text, sql : Text }
                ( \(migration : { name : Text, sql : Text }) ->
                    "        (\"${migration.name}.sql\", include_str!(\"../migrations/${migration.name}.sql\")),"
                )
                input.migrations

        let testsRs
            : Lude.File.Type
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
            : List Lude.File.Type

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        let compiledQueries
            : Lude.Compiled.Type (List (Optional QueryGen.Output))
            = Lude.Compiled.traverseList
                Project.Query
                (Optional QueryGen.Output)
                ( \(query : Project.Query) ->
                    Typeclasses.Classes.Alternative.optional
                      Lude.Compiled.Type
                      Lude.Compiled.alternative
                      QueryGen.Output
                      (QueryGen.run config query)
                )
                input.queries

        let compiledQueries
            : Lude.Compiled.Type (List QueryGen.Output)
            = Lude.Compiled.map
                (List (Optional QueryGen.Output))
                (List QueryGen.Output)
                (Prelude.List.unpackOptionals QueryGen.Output)
                compiledQueries

        let compiledTypes
            : Lude.Compiled.Type (List CustomTypeGen.Output)
            = Lude.Compiled.traverseList
                Project.CustomType
                CustomTypeGen.Output
                (CustomTypeGen.run config)
                input.customTypes

        let files
            : Lude.Compiled.Type (List Lude.File.Type)
            = Lude.Compiled.map2
                (List QueryGen.Output)
                (List CustomTypeGen.Output)
                (List Lude.File.Type)
                (combineOutputs config input)
                compiledQueries
                compiledTypes

        in  files

in  Algebra.Interpreter.module Input Output run
