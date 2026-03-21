let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Typeclasses = Deps.Typeclasses

let Sdk = Deps.Sdk

let Templates = ../Templates/package.dhall

let ResultModule = ./Result.dhall

let QueryFragmentsModule = ./QueryFragments.dhall

let MemberModule = ./Member.dhall

let Input = Deps.Sdk.Project.Query

let Output = { moduleName : Text, modulePath : Text, moduleContents : Text }

let render =
      \(config : Algebra.Config) ->
      \(input : Input) ->
      \(result : ResultModule.Output) ->
      \(fragments : QueryFragmentsModule.Output) ->
      \(params : List MemberModule.Output) ->
        let moduleName = Deps.CodegenKit.Name.toTextInSnake input.name

        let structName = Deps.CodegenKit.Name.toTextInPascal input.name

        let modulePath = "src/queries/${moduleName}.rs"

        let result = result structName

        let paramRefsExp =
              Deps.Prelude.Text.concatMapSep
                ", "
                MemberModule.Output
                (\(member : MemberModule.Output) -> member.toSqlRef)
                params

        let queryBody = result.queryBody paramRefsExp

        let moduleContents =
              Templates.QueryModule.run
                { moduleName
                , structName
                , srcPath = input.srcPath
                , sqlExp = fragments.exp
                , sqlDocComment = fragments.docComment
                , typeDecls = result.typeDecls
                , queryBody
                , paramFields =
                    Deps.Prelude.List.map
                      MemberModule.Output
                      Text
                      ( \(member : MemberModule.Output) ->
                          member.fieldDeclaration
                      )
                      params
                }

        in  { moduleName, modulePath, moduleContents }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        Sdk.Compiled.nest
          Output
          input.srcPath
          ( Typeclasses.Classes.Applicative.map3
              Sdk.Compiled.Type
              Sdk.Compiled.applicative
              ResultModule.Output
              QueryFragmentsModule.Output
              (List MemberModule.Output)
              Output
              (render config input)
              ( Sdk.Compiled.nest
                  ResultModule.Output
                  "result"
                  (ResultModule.run config input.result)
              )
              ( Sdk.Compiled.nest
                  QueryFragmentsModule.Output
                  "sql"
                  (QueryFragmentsModule.run config input.fragments)
              )
              ( Sdk.Compiled.nest
                  (List MemberModule.Output)
                  "params"
                  ( Typeclasses.Classes.Applicative.traverseList
                      Sdk.Compiled.Type
                      Sdk.Compiled.applicative
                      Deps.Sdk.Project.Member
                      MemberModule.Output
                      (MemberModule.run config)
                      input.params
                  )
              )
          )

in  Algebra.module Input Output run
