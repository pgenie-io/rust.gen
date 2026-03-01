let Deps = ../Deps/package.dhall

let Input = { modules : List Text }

let run =
      \(input : Input) ->
        ''
        //! Query modules providing type-safe database access.

        ${Deps.Prelude.Text.concatMap
            Text
            ( \(modName : Text) ->
                ''
                pub mod ${modName};
                ''
            )
            input.modules}''

in  { Input, run }
