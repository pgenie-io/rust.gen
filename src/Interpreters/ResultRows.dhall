let Sdk = ../Deps/Sdk.dhall

let InterpreterConfig = ../InterpreterConfig.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Typeclasses = ../Deps/Typeclasses.dhall

let Contract = ../Deps/Contract.dhall

let Member = ./ResultColumnsMember.dhall

let Templates = ../Templates/package.dhall

let Input = Contract.ResultRows

let Output =
      { cardinality : Contract.ResultRowsCardinality
      , columnFieldDeclarations : Text
      , singleDecodeFields : Text
      , multipleDecodeFields : Text
      , testRowFields : Text
      }

let run =
      \(config : InterpreterConfig.Type) ->
      \(input : Input) ->
        let compiledColumns =
              Typeclasses.Classes.Applicative.traverseList
                Lude.Compiled.Type
                Lude.Compiled.applicative
                Contract.Member
                Member.Output
                (Member.run config)
                (Prelude.NonEmpty.toList Contract.Member input.columns)

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
                      , testRowFields =
                          Prelude.Text.concatMapSep
                            ", "
                            Member.Output
                            ( \(col : Member.Output) ->
                                "${col.fieldName}: ${col.testValueExpr}"
                            )
                            columns
                      }
              )
              compiledColumns

in  Sdk.Sigs.interpreter InterpreterConfig.Type Input Output run
