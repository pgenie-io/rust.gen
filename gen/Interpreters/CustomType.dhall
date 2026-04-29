let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Project = ../Deps/Project.dhall

let Templates = ../Templates/package.dhall

let MemberGen = ./CustomTypeMember.dhall

let Input = Project.CustomType

let Output =
      { moduleName : Text
      , typeName : Text
      , modulePath : Text
      , moduleContent : Text
      }

in  Algebra.Interpreter.module
      Input
      Output
      ( \(config : Algebra.Interpreter.Config) ->
        \(input : Input) ->
          let typeName = Lude.Name.toTextInPascal input.name

          let moduleName = Lude.Name.toTextInSnake input.name

          let modulePath = "src/types/${moduleName}.rs"

          in  merge
                { Composite =
                    \(members : List Project.Member) ->
                      let compiledMembers
                          : Lude.Compiled.Type (List MemberGen.Output)
                          = Lude.Compiled.traverseList
                              Project.Member
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
                    \(variants : List Project.EnumVariant) ->
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
                                    Project.EnumVariant
                                    Templates.CustomEnumTypeModule.Variant
                                    ( \(variant : Project.EnumVariant) ->
                                        { name =
                                            Lude.Name.toTextInPascal
                                              variant.name
                                        , pgValue = variant.pgName
                                        }
                                    )
                                    variants
                              }
                        }
                , Domain =
                    \(value : Project.Value) ->
                      Lude.Compiled.message
                        Output
                        "Domain types are not yet supported."
                }
                input.definition
      )
