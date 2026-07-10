let Sdk = ./Deps/Sdk.dhall

let Contract = ./Deps/Contract.dhall

let InterpreterConfig = ./InterpreterConfig.dhall

let ProjectInterpreter = ./Interpreters/Project.dhall

let Config = { deadpool : Bool }

let defaultConfig = { deadpool = False }

let interpret =
      \(config : Config) ->
      \(project : Contract.Project) ->
        ProjectInterpreter.run
          (InterpreterConfig.resolve config project)
          project

in  Sdk.Sigs.generator Config defaultConfig interpret
