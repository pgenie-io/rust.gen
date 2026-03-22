let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Value = ./Value.dhall

let Input = Model.Member

let Output =
      { fieldName : Text
      , fieldType : Text
      , fieldDeclaration : Text
      , paramFieldDeclaration : Text
      , columnFieldDeclaration : Text
      , pgName : Text
      , paramExpr : Text
      , decoderExpr : Text
      , pgType : Text
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

              let fieldType =
                    if input.isNullable then "Option<${sig}>" else sig

              let indent = "    "

              let fieldDeclaration =
                        indent
                    ++  "/// Maps to `"
                    ++  input.pgName
                    ++  "`.\n"
                    ++  indent
                    ++  "pub "
                    ++  fieldName
                    ++  ": "
                    ++  fieldType
                    ++  ","

              let paramFieldDeclaration =
                        indent
                    ++  "/// Maps to `\$"
                    ++  input.pgName
                    ++  "` in the template.\n"
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
                    ++  "` result set column.\n"
                    ++  indent
                    ++  "pub "
                    ++  fieldName
                    ++  ": "
                    ++  fieldType
                    ++  ","

              let paramExpr = "&self.${fieldName}"

              let decoderExpr = "row.get(\"${input.pgName}\")"

              in  Sdk.Compiled.ok
                    Output
                    { fieldName
                    , fieldType
                    , fieldDeclaration
                    , paramFieldDeclaration
                    , columnFieldDeclaration
                    , pgName = input.pgName
                    , paramExpr
                    , decoderExpr
                    , pgType = value.pgType
                    }
          )
          ( Sdk.Compiled.nest
              Value.Output
              input.pgName
              (Value.run config input.value)
          )

in  Algebra.module Input Output run
