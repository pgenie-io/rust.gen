let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Value = ./Value.dhall

let Input = Model.Member

let Output =
      { fieldName : Text
      , fieldDeclaration : Text
      , fieldType : Text
      , toSqlRef : Text
      }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        Sdk.Compiled.flatMap
          Value.Output
          Output
          ( \(value : Value.Output) ->
              let fieldName = Deps.CodegenKit.Name.toTextInSnake input.name

              let sig = value.sig

              let sig = if input.isNullable then "Option<${sig}>" else sig

              in  Sdk.Compiled.ok
                    Output
                    { fieldName
                    , fieldType = sig
                    , fieldDeclaration =
                        ''
                            /// Maps to `${input.pgName}`.
                            pub ${fieldName}: ${sig},''
                    , toSqlRef =
                        "&params.${fieldName} as &(dyn postgres_types::ToSql + Sync)"
                    }
          )
          ( Sdk.Compiled.nest
              Value.Output
              input.pgName
              (Value.run config input.value)
          )

in  Algebra.module Input Output run
