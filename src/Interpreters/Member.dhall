let Sdk = ../Deps/Sdk.dhall

let InterpreterConfig = ../InterpreterConfig.dhall

let Lude = ../Deps/Lude.dhall

let Name = ./Name.dhall

let Contract = ../Deps/Contract.dhall

let Value = ./Value.dhall

let Input = Contract.Member

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
        let combine =
              \(name : Name.Output) ->
              \(value : Value.Output) ->
                let fieldName = name.fieldName

                let sig = value.sig

                let fieldType =
                      if input.isNullable then "Option<${sig}>" else sig

                let supportsDefault = input.isNullable || value.supportsDefault

                let testValueExpr =
                      if    input.isNullable
                      then  "Some(${value.testValueExpr})"
                      else  value.testValueExpr

                in  { fieldName
                    , fieldType
                    , pgName = input.pgName
                    , paramExpr = "&self.${fieldName}"
                    , pgType = value.pgType
                    , pgCastSuffix = value.pgCastSuffix
                    , supportsDefault
                    , testValueExpr
                    }

        in  Lude.Compiled.map2
              Name.Output
              Value.Output
              Output
              combine
              ( Lude.Compiled.nest
                  Name.Output
                  input.pgName
                  (Name.run config input.name)
              )
              ( Lude.Compiled.nest
                  Value.Output
                  input.pgName
                  (Value.run config input.value)
              )

in  Sdk.Sigs.interpreter InterpreterConfig.Type Input Output run
