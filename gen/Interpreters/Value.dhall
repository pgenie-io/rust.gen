let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Scalar = ./Scalar.dhall

let Input = Model.Value

let Output = { sig : Text }

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

                    in  Sdk.Compiled.ok Output { sig = "Vec<${elementSig}>" }
                )
                (Sdk.Compiled.ok Output { sig = scalar.sig })
          )
          (Scalar.run config input.scalar)

in  Algebra.module Input Output run
