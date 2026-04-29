let Project = ./Deps/Project.dhall

let Config = ./Config.dhall

let ProjectInterpreter = ./Interpreters/Project.dhall

let Lude = ./Deps/Lude.dhall

in  \(config : Optional Config) ->
    \(project : Project.Project) ->
      let interpreterConfig =
            { rootModuleName = Lude.Name.toTextInSnake project.name
            , deadpool =
                merge
                  { None = False, Some = \(c : Config) -> c.deadpool }
                  config
            }

      in  ProjectInterpreter.run interpreterConfig project
