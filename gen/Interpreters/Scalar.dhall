let Deps = ../Deps/package.dhall

let Algebra = ../Algebras/package.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Primitive = ./Primitive.dhall

let Input = Model.Scalar

let Output =
      { sig : Text, pgType : Text, pgCastSuffix : Text, hasKnownPgType : Bool }

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        merge
          { Primitive =
              \(primitive : Model.Primitive) -> Primitive.run config primitive
          , Custom =
              \(name : Model.Name) ->
                let pgName = Deps.CodegenKit.Name.toTextInSnake name

                in  Sdk.Compiled.ok
                      Output
                      { sig =
                          "crate::types::${Deps.CodegenKit.Name.toTextInPascal
                                             name}"
                      , pgType = "Type::UNKNOWN"
                      , pgCastSuffix = "::public.${pgName}"
                      , hasKnownPgType = False
                      }
          }
          input

in  Algebra.Interpreter.module Input Output run
