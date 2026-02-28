let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let ResultRows = ./ResultRows.dhall

let Input = Deps.Sdk.Project.Result

let Output = Text -> { typeDecls : Text, queryBody : Text -> Text }

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
                      /// Result of the `${typeNameBase}` query.
                      pub type ${typeNameBase}Result = u64;
                      ''
                  , queryBody =
                      \(paramsExp : Text) ->
                        "client.execute(SQL, &[${paramsExp}]).await"
                  }
              )
          )

in  Algebra.module Input Output run
