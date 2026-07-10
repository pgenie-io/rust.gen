let Sdk = ../Deps/Sdk.dhall

let InterpreterConfig = ../InterpreterConfig.dhall

let Lude = ../Deps/Lude.dhall

let Member = ./Member.dhall

let Input = Member.Input

let Output =
      { fieldName : Text
      , fieldType : Text
      , pgName : Text
      , paramExpr : Text
      , pgType : Text
      , pgCastSuffix : Text
      , supportsDefault : Bool
      , testValueExpr : Text
      }

let run =
      \(config : InterpreterConfig.Type) ->
      \(input : Input) ->
        Lude.Compiled.map
          Member.Output
          Output
          ( \(member : Member.Output) ->
              { fieldName = member.fieldName
              , fieldType = member.fieldType
              , pgName = member.pgName
              , paramExpr = member.paramExpr
              , pgType = member.pgType
              , pgCastSuffix = member.pgCastSuffix
              , supportsDefault = member.supportsDefault
              , testValueExpr = member.testValueExpr
              }
          )
          (Member.run config input)

in  Sdk.Sigs.interpreter InterpreterConfig.Type Input Output run
