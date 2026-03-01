let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Templates = ../Templates/package.dhall

let MemberGen = ./Member.dhall

let Input = Model.CustomType

let Output = { moduleName : Text, modulePath : Text, moduleContent : Text }

in  Algebra.module
      Input
      Output
      ( \(config : Algebra.Config) ->
        \(input : Input) ->
          let moduleName = Deps.CodegenKit.Name.toTextInSnake input.name

          let modulePath = "src/types/${moduleName}.rs"

          in  merge
                { Composite =
                    \(members : List Model.Member) ->
                      let compiledMembers
                          : Sdk.Compiled.Type (List MemberGen.Output)
                          = Sdk.Compiled.traverseList
                              Model.Member
                              MemberGen.Output
                              (MemberGen.run config)
                              members

                      let compiledOutput
                          : Sdk.Compiled.Type Output
                          = Sdk.Compiled.map
                              (List MemberGen.Output)
                              Output
                              ( \(members : List MemberGen.Output) ->
                                  { moduleName
                                  , modulePath
                                  , moduleContent =
                                      Templates.CompositeTypeModule.run
                                        { typeName =
                                            Deps.CodegenKit.Name.toTextInPascal
                                              input.name
                                        , pgSchema = input.pgSchema
                                        , pgTypeName = input.pgName
                                        , fieldDeclarations =
                                            Deps.Prelude.List.map
                                              MemberGen.Output
                                              Text
                                              ( \(member : MemberGen.Output) ->
                                                  member.fieldDeclaration
                                              )
                                              members
                                        }
                                  }
                              )
                              compiledMembers

                      in  compiledOutput
                , Enum =
                    \(variants : List Model.EnumVariant) ->
                      Sdk.Compiled.ok
                        Output
                        { moduleName
                        , modulePath
                        , moduleContent =
                            Templates.EnumTypeModule.run
                              { typeName =
                                  Deps.CodegenKit.Name.toTextInPascal input.name
                              , pgSchema = input.pgSchema
                              , pgTypeName = input.pgName
                              , variants =
                                  Deps.Prelude.List.map
                                    Model.EnumVariant
                                    Templates.EnumTypeModule.Variant
                                    ( \(variant : Model.EnumVariant) ->
                                        { name =
                                            Deps.CodegenKit.Name.toTextInPascal
                                              variant.name
                                        , pgValue = variant.pgName
                                        }
                                    )
                                    variants
                              }
                        }
                , Domain =
                    \(value : Model.Value) ->
                      Sdk.Compiled.message
                        Output
                        "Domain types are not yet supported."
                }
                input.definition
      )
