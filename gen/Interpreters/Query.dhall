let Deps = ../Deps/package.dhall

let Algebra = ../Algebras/package.dhall

let Lude = Deps.Lude

let Typeclasses = Deps.Typeclasses

let Sdk = Deps.Sdk

let Templates = ../Templates/package.dhall

let ResultModule = ./Result.dhall

let QueryFragmentsModule = ./QueryFragments.dhall

let MemberModule = ./ParamsMember.dhall

let Input = Deps.Sdk.Project.Query

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
        let statementModuleName = Deps.CodegenKit.Name.toTextInSnake input.name

        let statementModulePath = "src/statements/${statementModuleName}.rs"

        let queryName = Deps.CodegenKit.Name.toTextInSnake input.name

        let typeName = Deps.CodegenKit.Name.toTextInPascal input.name

        let paramExprs =
              Deps.Prelude.Text.concatMapSep
                ", "
                MemberModule.Output
                (\(member : MemberModule.Output) -> member.paramExpr)
                params

        let paramTypesText =
              Deps.Prelude.Text.concatMapSep
                ", "
                MemberModule.Output
                (\(member : MemberModule.Output) -> member.pgType)
                params

        let paramCastSuffixes =
              Deps.Prelude.List.map
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
              Deps.Prelude.Text.concatMapSep
                "\n"
                MemberModule.Output
                ( \(member : MemberModule.Output) ->
                    member.paramFieldDeclaration
                )
                params

        let sqlDocLines =
                  "/// "
              ++  Deps.Lude.Extensions.Text.prefixEachLine
                    "/// "
                    fragments.docComment

        let hasParams =
              Deps.Prelude.List.null MemberModule.Output params == False

        let canDeriveDefault =
              Deps.Prelude.List.all
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

in  Algebra.Interpreter.module Input Output run
