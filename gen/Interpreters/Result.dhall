let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let ResultRows = ./ResultRows.dhall

let Input = Deps.Sdk.Project.Result

let Output = Text -> { typeDecls : Text, decoderBlock : Text }

let Result = Deps.Sdk.Compiled.Type Output

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        Deps.Prelude.Optional.fold
          ResultRows.Input
          input
          Result
          (ResultRows.run config)
          ( Deps.Sdk.Compiled.ok
              Output
              ( \(typeNameBase : Text) ->
                  { typeDecls =
                      ''
                      /// Output type: number of rows affected.
                      pub type Output = u64;
                      ''
                  , decoderBlock = "rows_affected"
                  }
              )
          )

in  Algebra.module Input Output run
