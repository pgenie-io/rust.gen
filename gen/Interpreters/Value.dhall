let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Project = ../Deps/Project.dhall

let Scalar = ./Scalar.dhall

let Input = Project.Value

let Output =
      { sig : Text
      , pgType : Text
      , pgCastSuffix : Text
      , hasKnownPgType : Bool
      , supportsDefault : Bool
      }

let Result = Lude.Compiled.Type Output

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        Lude.Compiled.flatMap
          Scalar.Output
          Output
          ( \(scalar : Scalar.Output) ->
              Prelude.Optional.fold
                Project.ArraySettings
                input.arraySettings
                Result
                ( \(arraySettings : Project.ArraySettings) ->
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
                                ++  Prelude.Text.replicate
                                      arraySettings.dimensionality
                                      "[]"

                    in  Lude.Compiled.ok
                          Output
                          { sig = arraySig
                          , pgType = arrayPgType
                          , pgCastSuffix = arrayPgCastSuffix
                          , hasKnownPgType = scalar.hasKnownPgType
                          , supportsDefault = True
                          }
                )
                ( Lude.Compiled.ok
                    Output
                    { sig = scalar.sig
                    , pgType = scalar.pgType
                    , pgCastSuffix = scalar.pgCastSuffix
                    , hasKnownPgType = scalar.hasKnownPgType
                    , supportsDefault = scalar.supportsDefault
                    }
                )
          )
          (Scalar.run config input.scalar)

in  Algebra.Interpreter.module Input Output run
