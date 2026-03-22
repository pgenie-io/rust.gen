let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Lude = Deps.Lude

let Typeclasses = Deps.Typeclasses

let Sdk = Deps.Sdk

let Templates = ../Templates/package.dhall

let ResultModule = ./Result.dhall

let QueryFragmentsModule = ./QueryFragments.dhall

let MemberModule = ./Member.dhall

let Input = Deps.Sdk.Project.Query

let Output =
      { statementModuleName : Text
      , statementModulePath : Text
      , statementModuleContents : Text
      }

let render =
      \(config : Algebra.Config) ->
      \(input : Input) ->
      \(result : ResultModule.Output) ->
      \(fragments : QueryFragmentsModule.Output) ->
      \(params : List MemberModule.Output) ->
        let statementModuleName =
              Deps.CodegenKit.Name.toTextInSnake input.name

        let statementModulePath =
              "src/statements/${statementModuleName}.rs"

        let queryName = Deps.CodegenKit.Name.toTextInSnake input.name

        let typeName = Deps.CodegenKit.Name.toTextInPascal input.name

        let result = result typeName

        let paramFields =
              Deps.Prelude.Text.concatMap
                MemberModule.Output
                ( \(member : MemberModule.Output) ->
                    ''
                    ${member.fieldDeclaration},
                    ''
                )
                params

        let paramExprs =
              Deps.Prelude.Text.concatMapSep
                ", "
                MemberModule.Output
                (\(member : MemberModule.Output) -> member.paramExpr)
                params

        let decodeBody =
              merge
                { rows_affected =
                    ''
                            Ok(rows_affected)
                    ''
                , optional =
                    ''
                            match rows.into_iter().next() {
                                Some(row) => Ok(Some(OutputRow::from_row(&row))),
                                None => Ok(None),
                            }
                    ''
                , single =
                    ''
                            let row = rows.into_iter().next()
                                .expect("expected exactly one row");
                            Ok(OutputRow::from_row(&row))
                    ''
                , multiple =
                    ''
                            Ok(rows.iter().map(OutputRow::from_row).collect())
                    ''
                }
                result.decoderBlock

        let sqlDocLines =
              Deps.Lude.Extensions.Text.prefixEachLine
                "/// "
                fragments.docComment

        let statementModuleContents =
              Templates.StatementModule.run
                { queryName
                , typeName
                , srcPath = input.srcPath
                , sqlDocLines
                , sqlExp = fragments.sqlExp
                , paramFields
                , paramExprs
                , typeDecls = result.typeDecls
                , decodeBody
                , decoderBlock = result.decoderBlock
                }

        in  { statementModuleName
            , statementModulePath
            , statementModuleContents
            }

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
