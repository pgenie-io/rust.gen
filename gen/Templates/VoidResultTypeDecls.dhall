let Algebra = ../Algebras/package.dhall

let Params = {}

in  Algebra.Template.module
      Params
      ( \(_ : Params) ->
          ''
          /// Result of the statement parameterised by [`Input`].
          ///
          /// Contains no value.
          pub type Output = ();
          ''
      )
