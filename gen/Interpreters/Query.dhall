let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Typeclasses = ../Deps/Typeclasses.dhall

let Project = ../Deps/Project.dhall

let Templates = ../Templates/package.dhall

let ResultModule = ./Result.dhall

let QueryFragmentsModule = ./QueryFragments.dhall

let MemberModule = ./ParamsMember.dhall

let Input = Project.Query

let Output =
      { statementModuleName : Text
      , statementModulePath : Text
      , statementModuleContents : Text
      , canDeriveDefault : Bool
      }

let render =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
      \(result : ResultModule.Output) ->
      \(fragments : QueryFragmentsModule.Output) ->
      \(params : List MemberModule.Output) ->
        let statementModuleName = Lude.Name.toTextInSnake input.name

        let statementModulePath = "src/statements/${statementModuleName}.rs"

        let queryName = Lude.Name.toTextInSnake input.name

        let typeName = Lude.Name.toTextInPascal input.name

        let paramExprs =
              Prelude.Text.concatMapSep
                ", "
                MemberModule.Output
                (\(member : MemberModule.Output) -> member.paramExpr)
                params

        let paramTypesText =
              Prelude.Text.concatMapSep
                ", "
                MemberModule.Output
                (\(member : MemberModule.Output) -> member.pgType)
                params

        let paramCastSuffixes =
              Prelude.List.map
                MemberModule.Output
                Text
                (\(member : MemberModule.Output) -> member.pgCastSuffix)
                params

        let result =
              result
                { sqlExp = fragments.mkSqlExp paramCastSuffixes
                , paramTypes = paramTypesText
                , paramExprs
                }
                typeName

        let paramFields =
              Prelude.Text.concatMapSep
                "\n"
                MemberModule.Output
                ( \(member : MemberModule.Output) ->
                    member.paramFieldDeclaration
                )
                params

        let sqlDocLines =
              "/// " ++ Lude.Text.prefixEachLine "/// " fragments.docComment

        let hasParams = Prelude.List.null MemberModule.Output params == False

        let canDeriveDefault =
              Prelude.List.all
                MemberModule.Output
                (\(member : MemberModule.Output) -> member.supportsDefault)
                params

        let statementModuleContents =
              Templates.StatementModule.run
                { queryName
                , typeName
                , srcPath = input.srcPath
                , sqlDocLines
                , hasParams
                , canDeriveDefault
                , paramFields
                , typeDecls = result.typeDecls
                , statementImpl = result.statementImpl
                }

        in  { statementModuleName
            , statementModulePath
            , statementModuleContents
            , canDeriveDefault
            }

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        Lude.Compiled.nest
          Output
          input.srcPath
          ( Typeclasses.Classes.Applicative.map3
              Lude.Compiled.Type
              Lude.Compiled.applicative
              ResultModule.Output
              QueryFragmentsModule.Output
              (List MemberModule.Output)
              Output
              (render config input)
              ( Lude.Compiled.nest
                  ResultModule.Output
                  "result"
                  (ResultModule.run config input.result)
              )
              ( Lude.Compiled.nest
                  QueryFragmentsModule.Output
                  "sql"
                  (QueryFragmentsModule.run config input.fragments)
              )
              ( Lude.Compiled.nest
                  (List MemberModule.Output)
                  "params"
                  ( Typeclasses.Classes.Applicative.traverseList
                      Lude.Compiled.Type
                      Lude.Compiled.applicative
                      Project.Member
                      MemberModule.Output
                      (MemberModule.run config)
                      input.params
                  )
              )
          )

in  Algebra.Interpreter.module Input Output run
