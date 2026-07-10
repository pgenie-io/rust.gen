let Contract = ./Deps/Contract.dhall

let InterpreterConfig = { rootModuleName : Text, deadpool : Bool }

let resolve =
      \(config : { deadpool : Bool }) ->
      \(project : Contract.Project) ->
          { rootModuleName = project.name.inSnakeCase
          , deadpool = config.deadpool
          }
        : InterpreterConfig

in  { Type = InterpreterConfig, resolve }
