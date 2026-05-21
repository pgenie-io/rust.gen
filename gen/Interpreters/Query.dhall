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
      , testInputExpr : Text
      }

let isMultiDimensional =
      \(value : Project.Value) ->
        merge
          { Some =
              \(arraySettings : Project.ArraySettings) ->
                    Natural/isZero
                      (Natural/subtract 1 arraySettings.dimensionality)
                ==  False
          , None = False
          }
          value.arraySettings

let queryHasMultiDimensionalArray =
      \(input : Input) ->
        let paramsHaveMultiDimensional =
              Prelude.List.any
                Project.Member
                (\(member : Project.Member) -> isMultiDimensional member.value)
                input.params

        let resultColumnsHaveMultiDimensional =
              merge
                { Some =
                    \(resultRows : Project.ResultRows) ->
                      Prelude.List.any
                        Project.Member
                        ( \(member : Project.Member) ->
                            isMultiDimensional member.value
                        )
                        ( Prelude.NonEmpty.toList
                            Project.Member
                            resultRows.columns
                        )
                , None = False
                }
                input.result

        in  paramsHaveMultiDimensional || resultColumnsHaveMultiDimensional

let render =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
      \(result : ResultModule.Output) ->
      \(fragments : QueryFragmentsModule.Output) ->
      \(params : List MemberModule.Output) ->
        let statementModuleName = input.name.inSnakeCase

        let statementModulePath = "src/statements/${statementModuleName}.rs"

        let queryName = input.name.inSnakeCase

        let typeName = input.name.inPascalCase

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

        let testParamFields =
              Prelude.Text.concatMapSep
                "\n"
                MemberModule.Output
                ( \(member : MemberModule.Output) ->
                    "    ${member.fieldName}: ${member.testValueExpr},"
                )
                params

        let testInputExpr =
              if    hasParams
              then      ''
                        statements::${statementModuleName}::Input {
                        ''
                    ++  testParamFields
                    ++  ''

                        }''
              else  "statements::${statementModuleName}::Input::default()"

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
            , testInputExpr
            }

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        if    queryHasMultiDimensionalArray input
        then  Lude.Compiled.report
                Output
                [ input.srcPath ]
                "Multidimensional arrays are not supported by tokio-postgres; skipping statement"
        else  Lude.Compiled.nest
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
