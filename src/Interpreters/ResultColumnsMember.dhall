let Sdk = ../Deps/Sdk.dhall

let InterpreterConfig = ../InterpreterConfig.dhall

let Lude = ../Deps/Lude.dhall

let Member = ./Member.dhall

let Templates = ../Templates/package.dhall

let Input = Member.Input

let Output =
      { fieldName : Text
      , fieldType : Text
      , columnFieldDeclaration : Text
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
              , columnFieldDeclaration =
                  Templates.ColumnField.run
                    { pgName = member.pgName
                    , fieldName = member.fieldName
                    , fieldType = member.fieldType
                    }
              , testValueExpr = member.testValueExpr
              }
          )
          (Member.run config input)

in  Sdk.Sigs.interpreter InterpreterConfig.Type Input Output run
