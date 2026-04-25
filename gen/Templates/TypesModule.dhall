let Algebra = ../Algebras/package.dhall

let Params = { typeModNames : Text, typeReexports : Text }

in  Algebra.Template.module
      Params
      ( \(params : Params) ->
          ''
          ${params.typeModNames}
          ${params.typeReexports}
          ''
      )
