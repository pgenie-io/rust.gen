let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Typeclasses = ../Deps/Typeclasses.dhall

let Project = ../Deps/Project.dhall

let Templates = ../Templates/package.dhall

let ResultRowsModule = ./ResultRows.dhall

let MemberModule = ./ParamsMember.dhall

let Input = Project.Query

let Output =
      { statementModuleName : Text
      , statementModulePath : Text
      , statementModuleContents : Text
      , canDeriveDefault : Bool
      , testInputExpr : Text
      , isIdentity : Bool
      , identityTestExpectedExpr : Optional Text
      }

let ResultInterpretation =
      < Void | RowsAffected | Rows : ResultRowsModule.Output >

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
                { Void = False
                , RowsAffected = False
                , Rows =
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
                }
                input.result

        in  paramsHaveMultiDimensional || resultColumnsHaveMultiDimensional

let escapeRustString
    : Text -> Text
    = Prelude.Function.composeList
        Text
        [ Prelude.Text.replace "\\" "\\\\"
        , Prelude.Text.replace "\"" "\\\""
        , Prelude.Text.replace
            "\n"
            ''
            \n\
            ''
        ]

let renderSqlExp
    : Project.QueryFragments -> List Text -> Text
    = \(fragments : Project.QueryFragments) ->
      \(castSuffixes : List Text) ->
        "\"${Prelude.Text.concatMap
               Project.QueryFragment
               ( \(queryFragment : Project.QueryFragment) ->
                   merge
                     { Sql = escapeRustString
                     , Var =
                         \(var : Project.Var) ->
                           let suffix =
                                 Prelude.Optional.fold
                                   Text
                                   ( Prelude.List.index
                                       var.paramIndex
                                       Text
                                       castSuffixes
                                   )
                                   Text
                                   (\(s : Text) -> s)
                                   ""

                           in  "\$${Natural/show (var.paramIndex + 1)}${suffix}"
                     }
                     queryFragment
               )
               fragments}\""

let renderDocComment
    : Project.QueryFragments -> Text
    = Prelude.Text.concatMap
        Project.QueryFragment
        ( \(queryFragment : Project.QueryFragment) ->
            merge
              { Sql = Prelude.Function.identity Text
              , Var = \(var : Project.Var) -> "\$${var.rawName}"
              }
              queryFragment
        )

let render =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
      \(resultInterpretation : ResultInterpretation) ->
      \(params : List MemberModule.Output) ->
        let statementModuleName = input.name.inSnakeCase

        let statementModulePath = "src/statements/${statementModuleName}.rs"

        let queryName = input.name.inSnakeCase

        let typeName = input.name.inPascalCase

        let paramCastSuffixes =
              Prelude.List.map
                MemberModule.Output
                Text
                (\(member : MemberModule.Output) -> member.pgCastSuffix)
                params

        let sqlExp = renderSqlExp input.fragments paramCastSuffixes

        let docComment = renderDocComment input.fragments

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

        let paramFields =
              Prelude.Text.concatMapSep
                "\n"
                MemberModule.Output
                ( \(member : MemberModule.Output) ->
                    Templates.ParamField.run
                      { pgName = member.pgName
                      , fieldName = member.fieldName
                      , fieldType = member.fieldType
                      }
                )
                params

        let result =
              merge
                { Void =
                  { typeDecls = Templates.VoidResultTypeDecls.run {=}
                  , statementImpl =
                      Templates.StatementImplVoid.run
                        { sqlExp, paramTypes = paramTypesText, paramExprs }
                  }
                , RowsAffected =
                  { typeDecls = Templates.NoResultTypeDecls.run {=}
                  , statementImpl =
                      Templates.StatementImplNoResult.run
                        { sqlExp, paramTypes = paramTypesText, paramExprs }
                  }
                , Rows =
                    \(rows : ResultRowsModule.Output) ->
                      let rowTypeDecl =
                            Templates.OutputRowStruct.run
                              { fields = rows.columnFieldDeclarations }

                      let resultTypeAlias =
                            merge
                              { Single = "OutputRow"
                              , Optional = "Option<OutputRow>"
                              , Multiple = "Vec<OutputRow>"
                              }
                              rows.cardinality

                      let typeDecls =
                            Prelude.Text.concat
                              [ Templates.ResultTypeAlias.run
                                  { alias = resultTypeAlias }
                              , "\n"
                              , rowTypeDecl
                              , "\n"
                              ]

                      let decodeBody =
                            merge
                              { Single =
                                  Templates.DecodeBodySingle.run
                                    { fields = rows.singleDecodeFields }
                              , Optional =
                                  Templates.DecodeBodyOptional.run
                                    { fields = rows.singleDecodeFields }
                              , Multiple =
                                  Templates.DecodeBodyMultiple.run
                                    { fields = rows.multipleDecodeFields }
                              }
                              rows.cardinality

                      let statementImpl =
                            Templates.StatementImplWithResult.run
                              { sqlExp
                              , paramTypes = paramTypesText
                              , paramExprs
                              , decodeBody
                              }

                      in  { typeDecls, statementImpl }
                }
                resultInterpretation

        let sqlDocLines = "/// ${Lude.Text.prefixEachLine "/// " docComment}"

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
                    "${member.fieldName}: ${member.testValueExpr},"
                )
                params

        let testInputExpr =
              if    hasParams
              then  ''
                    statements::${statementModuleName}::Input {
                        ${Lude.Text.indentNonEmpty 4 testParamFields}
                    }''
              else  "statements::${statementModuleName}::Input::default()"

        let identityTestExpectedExpr =
              merge
                { Void = None Text
                , RowsAffected = None Text
                , Rows =
                    \(rows : ResultRowsModule.Output) ->
                      if    input.identity == False
                      then  None Text
                      else  let rowFields = rows.testRowFields

                            let rowExpr =
                                  "statements::${statementModuleName}::OutputRow { ${rowFields} }"

                            let wrappedExpr =
                                  merge
                                    { Single = rowExpr
                                    , Optional = "Some(${rowExpr})"
                                    , Multiple = "vec![${rowExpr}]"
                                    }
                                    rows.cardinality

                            in  Some wrappedExpr
                }
                resultInterpretation

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
            , isIdentity = input.identity
            , identityTestExpectedExpr
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
                ( Typeclasses.Classes.Applicative.map2
                    Lude.Compiled.Type
                    Lude.Compiled.applicative
                    ResultInterpretation
                    (List MemberModule.Output)
                    Output
                    (render config input)
                    ( Lude.Compiled.nest
                        ResultInterpretation
                        "result"
                        ( merge
                            { Void =
                                Lude.Compiled.ok
                                  ResultInterpretation
                                  ResultInterpretation.Void
                            , RowsAffected =
                                Lude.Compiled.ok
                                  ResultInterpretation
                                  ResultInterpretation.RowsAffected
                            , Rows =
                                \(resultRowsInput : Project.ResultRows) ->
                                  Lude.Compiled.map
                                    ResultRowsModule.Output
                                    ResultInterpretation
                                    ( \(o : ResultRowsModule.Output) ->
                                        ResultInterpretation.Rows o
                                    )
                                    ( ResultRowsModule.run
                                        config
                                        resultRowsInput
                                    )
                            }
                            input.result
                        )
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
