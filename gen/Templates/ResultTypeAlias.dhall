let Algebra = ../Algebras/package.dhall

let Params = { alias : Text }

in  Algebra.Template.module
      Params
      ( \(params : Params) ->
          ''
          /// Result of the statement parameterised by [`Input`].
          pub type Output = ${params.alias};
          ''
      )
