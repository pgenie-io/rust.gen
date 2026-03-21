let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Primitive = ./Primitive.dhall

let Input = Model.Scalar

let Output = { sig : Text }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        merge
          { Primitive =
              \(primitive : Model.Primitive) ->
                Sdk.Compiled.map
                  Primitive.Output
                  Output
                  (\(primitive : Primitive.Output) -> { sig = primitive.sig })
                  (Primitive.run config primitive)
          , Custom =
              \(name : Model.Name) ->
                Sdk.Compiled.ok
                  Output
                  { sig =
                          "crate::types::"
                      ++  Deps.CodegenKit.Name.toTextInPascal name
                  }
          }
          input

in  Algebra.module Input Output run
