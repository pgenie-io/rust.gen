let Sdk = ../Deps/Sdk.dhall

let InterpreterConfig = ../InterpreterConfig.dhall

let Lude = ../Deps/Lude.dhall

let Contract = ../Deps/Contract.dhall

let Primitive = ./Primitive.dhall

let Input = Contract.Scalar

let Output =
      { sig : Text
      , pgType : Text
      , pgCastSuffix : Text
      , hasKnownPgType : Bool
      , supportsDefault : Bool
      , testValueExpr : Text
      }

let run =
      \(config : InterpreterConfig.Type) ->
      \(input : Input) ->
        merge
          { Primitive =
              \(primitive : Contract.Primitive) ->
                Primitive.run config primitive
          , Custom =
              \(name : Contract.Name) ->
                let pgName = name.inSnakeCase

                in  Lude.Compiled.ok
                      Output
                      { sig = "crate::types::${name.inPascalCase}"
                      , pgType = "Type::UNKNOWN"
                      , pgCastSuffix = "::public.${pgName}"
                      , hasKnownPgType = False
                      , supportsDefault = False
                      , testValueExpr = "Default::default()"
                      }
          }
          input

in  Sdk.Sigs.interpreter InterpreterConfig.Type Input Output run
