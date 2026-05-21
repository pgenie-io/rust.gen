let Algebra = ../Algebras/package.dhall

let Params =
      { fieldName : Text
      , colIndex : Natural
      , rowVar : Text
      , rowIndexExpr : Text
      }

in  Algebra.Template.module
      Params
      ( \(params : Params) ->
          "${params.fieldName}: crate::mapping::decode_cell(${params.rowVar}, ${params.rowIndexExpr}, ${Natural/show
                                                                                                          params.colIndex})?,"
      )
