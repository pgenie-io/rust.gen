let Prelude = ./Deps/Prelude.dhall

let Lude = ./Deps/Lude.dhall

let Project = ./Deps/Project.dhall

let Config = ./Config.dhall

let compile = ./compile.dhall

let ContractVersion = { major : Natural, minor : Natural }

let contractVersion
    : ContractVersion
    = { major = 1, minor = 0 }

let compileToFileMap
    : Optional Config -> Project.Project -> Prelude.Map.Type Text Text
    = \(config : Optional Config) ->
      \(project : Project.Project) ->
        let compiledFiles = compile config project

        let compiledFileMap =
              Lude.Compiled.map
                Lude.Files.Type
                (Prelude.Map.Type Text Text)
                Lude.Files.toFileMap
                compiledFiles

        let fileMap = Lude.Compiled.toFileMap compiledFileMap

        in  fileMap

in  { contractVersion, Config, compile, compileToFileMap }
