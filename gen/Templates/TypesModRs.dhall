let Deps = ../Deps/package.dhall

let Input = { modules : List Text }

let run =
      \(input : Input) ->
        ''
        //! Custom PostgreSQL types.

        ${Deps.Prelude.Text.concatMap
            Text
            ( \(modName : Text) ->
                ''
                pub mod ${modName};
                pub use ${modName}::*;
                ''
            )
            input.modules}''

in  { Input, run }
