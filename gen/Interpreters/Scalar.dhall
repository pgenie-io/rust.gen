let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Project = ../Deps/Project.dhall

let Primitive = ./Primitive.dhall

let Input = Project.Scalar

let Output =
      { sig : Text
      , pgType : Text
      , pgCastSuffix : Text
      , hasKnownPgType : Bool
      , supportsDefault : Bool
      }

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        merge
          { Primitive =
              \(primitive : Project.Primitive) -> Primitive.run config primitive
          , Custom =
              \(name : Project.Name) ->
                let pgName = Lude.Name.toTextInSnake name

                in  Lude.Compiled.ok
                      Output
                      { sig = "crate::types::${Lude.Name.toTextInPascal name}"
                      , pgType = "Type::UNKNOWN"
                      , pgCastSuffix = "::public.${pgName}"
                      , hasKnownPgType = False
                      , supportsDefault = False
                      }
          }
          input

in  Algebra.Interpreter.module Input Output run
