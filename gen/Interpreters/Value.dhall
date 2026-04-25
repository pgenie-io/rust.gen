let Deps = ../Deps/package.dhall

let Algebra = ../Algebras/package.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Scalar = ./Scalar.dhall

let Input = Model.Value

let Output =
      { sig : Text, pgType : Text, pgCastSuffix : Text, hasKnownPgType : Bool }

let Result = Sdk.Compiled.Type Output

let run =
      \(config : Algebra.Interpreter.Config) ->
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

                    let arrayPgType =
                          if    scalar.hasKnownPgType
                          then  scalar.pgType ++ "_ARRAY"
                          else  scalar.pgType

                    let arrayPgCastSuffix =
                          if    scalar.hasKnownPgType
                          then  ""
                          else      scalar.pgCastSuffix
                                ++  Deps.Prelude.Text.replicate
                                      arraySettings.dimensionality
                                      "[]"

                    in  Sdk.Compiled.ok
                          Output
                          { sig = arraySig
                          , pgType = arrayPgType
                          , pgCastSuffix = arrayPgCastSuffix
                          , hasKnownPgType = scalar.hasKnownPgType
                          }
                )
                ( Sdk.Compiled.ok
                    Output
                    { sig = scalar.sig
                    , pgType = scalar.pgType
                    , pgCastSuffix = scalar.pgCastSuffix
                    , hasKnownPgType = scalar.hasKnownPgType
                    }
                )
          )
          (Scalar.run config input.scalar)

in  Algebra.Interpreter.module Input Output run
