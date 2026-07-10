let Sdk = ../Deps/Sdk.dhall

let Config = { deadpool : Bool }

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Contract = ../Deps/Contract.dhall

let Templates = ../Templates/package.dhall

let MemberGen = ./CustomTypeMember.dhall

let Input = Contract.CustomType

let Output =
      { moduleName : Text
      , typeName : Text
      , modulePath : Text
      , moduleContent : Text
      }

in  Sdk.Sigs.interpreter
      Config
      Input
      Output
      ( \(config : Config) ->
        \(input : Input) ->
          let typeName = input.name.inPascalCase

          let moduleName = input.name.inSnakeCase

          let modulePath = "src/types/${moduleName}.rs"

          in  merge
                { Composite =
                    \(members : List Contract.Member) ->
                      let compiledMembers
                          : Lude.Compiled.Type (List MemberGen.Output)
                          = Lude.Compiled.traverseList
                              Contract.Member
                              MemberGen.Output
                              (MemberGen.run config)
                              members

                      let compiledOutput
                          : Lude.Compiled.Type Output
                          = Lude.Compiled.map
                              (List MemberGen.Output)
                              Output
                              ( \(members : List MemberGen.Output) ->
                                  { moduleName
                                  , typeName
                                  , modulePath
                                  , moduleContent =
                                      Templates.CustomCompositeTypeModule.run
                                        { typeName
                                        , pgSchema = input.pgSchema
                                        , pgTypeName = input.pgName
                                        , fields =
                                            Prelude.List.map
                                              MemberGen.Output
                                              Templates.CustomCompositeTypeModule.Field
                                              ( \(member : MemberGen.Output) ->
                                                  { pgName = member.pgName
                                                  , fieldName = member.fieldName
                                                  , fieldType = member.fieldType
                                                  }
                                              )
                                              members
                                        }
                                  }
                              )
                              compiledMembers

                      in  compiledOutput
                , Enum =
                    \(variants : List Contract.EnumVariant) ->
                      Lude.Compiled.ok
                        Output
                        { moduleName
                        , typeName
                        , modulePath
                        , moduleContent =
                            Templates.CustomEnumTypeModule.run
                              { typeName
                              , pgSchema = input.pgSchema
                              , pgTypeName = input.pgName
                              , variants =
                                  Prelude.List.map
                                    Contract.EnumVariant
                                    Templates.CustomEnumTypeModule.Variant
                                    ( \(variant : Contract.EnumVariant) ->
                                        { name = variant.name.inPascalCase
                                        , pgValue = variant.pgName
                                        }
                                    )
                                    variants
                              }
                        }
                , Domain =
                    \(value : Contract.Value) ->
                      Lude.Compiled.message
                        Output
                        "Domain types are not yet supported."
                }
                input.definition
      )
