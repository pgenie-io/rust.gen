let Sdk = ../Deps/Sdk.dhall

let InterpreterConfig = ../InterpreterConfig.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Contract = ../Deps/Contract.dhall

let Scalar = ./Scalar.dhall

let Input = Contract.Value

let Output =
      { sig : Text
      , pgType : Text
      , pgCastSuffix : Text
      , hasKnownPgType : Bool
      , supportsDefault : Bool
      , testValueExpr : Text
      }

let Result = Lude.Compiled.Type Output

let run =
      \(config : InterpreterConfig.Type) ->
      \(input : Input) ->
        Lude.Compiled.flatMap
          Scalar.Output
          Output
          ( \(scalar : Scalar.Output) ->
              Prelude.Optional.fold
                Contract.ArraySettings
                input.arraySettings
                Result
                ( \(arraySettings : Contract.ArraySettings) ->
                    let elementSig =
                          if    arraySettings.elementIsNullable
                          then  "Option<${scalar.sig}>"
                          else  scalar.sig

                    let arraySig =
                          Natural/fold
                            arraySettings.dimensionality
                            Text
                            (\(inner : Text) -> "Vec<${inner}>")
                            elementSig

                    let arrayPgType =
                          if    scalar.hasKnownPgType
                          then  "${scalar.pgType}_ARRAY"
                          else  scalar.pgType

                    let arrayPgCastSuffix =
                          if    scalar.hasKnownPgType
                          then  ""
                          else  "${scalar.pgCastSuffix}${Prelude.Text.replicate
                                                           arraySettings.dimensionality
                                                           "[]"}"

                    let elementTestValue =
                          if    arraySettings.elementIsNullable
                          then  "Some(${scalar.testValueExpr})"
                          else  scalar.testValueExpr

                    let arrayTestValue =
                          Natural/fold
                            arraySettings.dimensionality
                            Text
                            (\(inner : Text) -> "vec![${inner}]")
                            elementTestValue

                    in  Lude.Compiled.ok
                          Output
                          { sig = arraySig
                          , pgType = arrayPgType
                          , pgCastSuffix = arrayPgCastSuffix
                          , hasKnownPgType = scalar.hasKnownPgType
                          , supportsDefault = True
                          , testValueExpr = arrayTestValue
                          }
                )
                ( Lude.Compiled.ok
                    Output
                    { sig = scalar.sig
                    , pgType = scalar.pgType
                    , pgCastSuffix = scalar.pgCastSuffix
                    , hasKnownPgType = scalar.hasKnownPgType
                    , supportsDefault = scalar.supportsDefault
                    , testValueExpr = scalar.testValueExpr
                    }
                )
          )
          (Scalar.run config input.scalar)

in  Sdk.Sigs.interpreter InterpreterConfig.Type Input Output run
