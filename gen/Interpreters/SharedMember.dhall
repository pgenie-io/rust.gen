let Deps = ../Deps/package.dhall

let Algebra = ../Algebras/package.dhall

let Rust = ./Rust.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Value = ./Value.dhall

let Input = Model.Member

let Output =
      { fieldName : Text
      , fieldType : Text
      , paramFieldDeclaration : Text
      , columnFieldDeclaration : Text
      , pgName : Text
      , paramExpr : Text
      , pgType : Text
      , pgCastSuffix : Text
      , supportsDefault : Bool
      }

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        Sdk.Compiled.flatMap
          Value.Output
          Output
          ( \(value : Value.Output) ->
              let rawFieldName = Deps.CodegenKit.Name.toTextInSnake input.name

              let fieldName =
                    if    Rust.isRustKeywordName input.name
                    then  rawFieldName ++ "_"
                    else  rawFieldName

              let sig = value.sig

              let fieldType = if input.isNullable then "Option<${sig}>" else sig

              let supportsDefault = input.isNullable || value.supportsDefault

              let indent = "    "

              let paramFieldDeclaration =
                        indent
                    ++  "/// Maps to `\$"
                    ++  input.pgName
                    ++  ''
                        ` in the template.
                        ''
                    ++  indent
                    ++  "pub "
                    ++  fieldName
                    ++  ": "
                    ++  fieldType
                    ++  ","

              let columnFieldDeclaration =
                        indent
                    ++  "/// Maps to the `"
                    ++  input.pgName
                    ++  ''
                        ` result set column.
                        ''
                    ++  indent
                    ++  "pub "
                    ++  fieldName
                    ++  ": "
                    ++  fieldType
                    ++  ","

              in  Sdk.Compiled.ok
                    Output
                    { fieldName
                    , fieldType
                    , paramFieldDeclaration
                    , columnFieldDeclaration
                    , pgName = input.pgName
                    , paramExpr = "&self.${fieldName}"
                    , pgType = value.pgType
                    , pgCastSuffix = value.pgCastSuffix
                    , supportsDefault
                    }
          )
          ( Sdk.Compiled.nest
              Value.Output
              input.pgName
              (Value.run config input.value)
          )

in  Algebra.Interpreter.module Input Output run
