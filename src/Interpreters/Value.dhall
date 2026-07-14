let Sdk = ../Deps/Sdk.dhall

let Config = { deadpool : Bool }

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

let run =
      \(config : Config) ->
      \(input : Input) ->
        Lude.Compiled.flatMap
          Scalar.Output
          Output
          ( \(scalar : Scalar.Output) ->
              let elementSig =
                    if    input.elementIsNullable
                    then  "Option<${scalar.sig}>"
                    else  scalar.sig

              let sig =
                    Natural/fold
                      input.dimensionality
                      Text
                      (\(inner : Text) -> "Vec<${inner}>")
                      elementSig

              let pgType =
                    if    Natural/isZero input.dimensionality
                    then  scalar.pgType
                    else  if    scalar.hasKnownPgType
                          then  "${scalar.pgType}_ARRAY"
                          else  scalar.pgType

              let pgCastSuffix =
                    if    scalar.hasKnownPgType
                    then  ""
                    else  "${scalar.pgCastSuffix}${Prelude.Text.replicate
                                                     input.dimensionality
                                                     "[]"}"

              let supportsDefault =
                    if    Natural/isZero input.dimensionality
                    then  scalar.supportsDefault
                    else  True

              let elementTestValue =
                    if    input.elementIsNullable
                    then  "Some(${scalar.testValueExpr})"
                    else  scalar.testValueExpr

              let testValueExpr =
                    Natural/fold
                      input.dimensionality
                      Text
                      (\(inner : Text) -> "vec![${inner}]")
                      elementTestValue

              in  Lude.Compiled.ok
                    Output
                    { sig
                    , pgType
                    , pgCastSuffix
                    , hasKnownPgType = scalar.hasKnownPgType
                    , supportsDefault
                    , testValueExpr
                    }
          )
          (Scalar.run config input.scalar)

in  Sdk.Sigs.interpreter Config Input Output run
