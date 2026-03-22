let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Primitive = ./Primitive.dhall

let Input = Model.Scalar

let Output = { sig : Text, pgType : Text, pgCastSuffix : Text }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        merge
          { Primitive =
              \(primitive : Model.Primitive) ->
                Sdk.Compiled.map
                  Primitive.Output
                  Output
                  ( \(p : Primitive.Output) ->
                      { sig = p.sig, pgType = p.pgType, pgCastSuffix = "" }
                  )
                  (Primitive.run config primitive)
          , Custom =
              \(name : Model.Name) ->
                let pgName = Deps.CodegenKit.Name.toTextInSnake name

                in  Sdk.Compiled.ok
                      Output
                      { sig =
                          "crate::types::${Deps.CodegenKit.Name.toTextInPascal name}"
                      , pgType = "Type::UNKNOWN"
                      , pgCastSuffix = "::public.${pgName}"
                      }
          }
          input

in  Algebra.module Input Output run
