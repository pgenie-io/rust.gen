let Contract = ./Deps/Contract.dhall

let Config = ./Config.dhall

let ResolvedTarget = { rootModuleName : Text, deadpool : Bool }

let resolve =
      \(config : Optional Config) ->
      \(project : Contract.Project) ->
          { rootModuleName = project.name.inSnakeCase
          , deadpool =
              merge { None = False, Some = \(c : Config) -> c.deadpool } config
          }
        : ResolvedTarget

in  { Type = ResolvedTarget, resolve }
