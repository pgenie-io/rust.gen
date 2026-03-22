let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Scalar = ./Scalar.dhall

let Input = Model.Value

let Output = { sig : Text, pgType : Text, pgCastSuffix : Text }

let Result = Sdk.Compiled.Type Output

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        Sdk.Compiled.flatMap
          Scalar.Output
          Output
          ( \(scalar : Scalar.Output) ->
              Deps.Prelude.Optional.fold
                Model.ArraySettings
                input.arraySettings
                Result
                ( \(arraySettings : Model.ArraySettings) ->
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

                    in  Sdk.Compiled.ok
                          Output
                          { sig = arraySig
                          , pgType = scalar.pgType
                          , pgCastSuffix = scalar.pgCastSuffix
                          }
                )
                ( Sdk.Compiled.ok
                    Output
                    { sig = scalar.sig
                    , pgType = scalar.pgType
                    , pgCastSuffix = scalar.pgCastSuffix
                    }
                )
          )
          (Scalar.run config input.scalar)

in  Algebra.module Input Output run
