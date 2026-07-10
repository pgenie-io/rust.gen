let Sdk = ../Deps/Sdk.dhall

let Params =
      { fieldName : Text
      , colIndex : Natural
      , rowVar : Text
      , rowIndexExpr : Text
      }

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
          "${params.fieldName}: crate::mapping::decode_cell(${params.rowVar}, ${params.rowIndexExpr}, ${Natural/show
                                                                                                          params.colIndex})?,"
      )
