let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Typeclasses = ../Deps/Typeclasses.dhall

let Project = ../Deps/Project.dhall

let Member = ./ResultColumnsMember.dhall

let Templates = ../Templates/package.dhall

let Input = Project.ResultRows

let Output =
      { cardinality : Project.ResultRowsCardinality
      , columnFieldDeclarations : Text
      , singleDecodeFields : Text
      , multipleDecodeFields : Text
      }

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        let compiledColumns =
              Typeclasses.Classes.Applicative.traverseList
                Lude.Compiled.Type
                Lude.Compiled.applicative
                Project.Member
                Member.Output
                (Member.run config)
                (Prelude.NonEmpty.toList Project.Member input.columns)

        in  Lude.Compiled.map
              (List Member.Output)
              Output
              ( \(columns : List Member.Output) ->
                  let indexedColumns =
                        Prelude.List.indexed Member.Output columns

                  in  { cardinality = input.cardinality
                      , columnFieldDeclarations =
                          Prelude.Text.concatMapSep
                            "\n"
                            Member.Output
                            ( \(col : Member.Output) ->
                                col.columnFieldDeclaration
                            )
                            columns
                      , singleDecodeFields =
                          Prelude.Text.concatSep
                            "\n"
                            ( Prelude.List.map
                                { index : Natural, value : Member.Output }
                                Text
                                ( \ ( ic
                                    : { index : Natural, value : Member.Output }
                                    ) ->
                                    Templates.DecodeField.run
                                      { fieldName = ic.value.fieldName
                                      , colIndex = ic.index
                                      , rowVar = "row"
                                      , rowIndexExpr = "0"
                                      }
                                )
                                indexedColumns
                            )
                      , multipleDecodeFields =
                          Prelude.Text.concatSep
                            "\n"
                            ( Prelude.List.map
                                { index : Natural, value : Member.Output }
                                Text
                                ( \ ( ic
                                    : { index : Natural, value : Member.Output }
                                    ) ->
                                    Templates.DecodeField.run
                                      { fieldName = ic.value.fieldName
                                      , colIndex = ic.index
                                      , rowVar = "&row"
                                      , rowIndexExpr = "row_index"
                                      }
                                )
                                indexedColumns
                            )
                      }
              )
              compiledColumns

in  Algebra.Interpreter.module Input Output run
