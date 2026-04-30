let Algebra = ../Algebras/Interpreter.dhall

let Lude = ../Deps/Lude.dhall

let Name = ./Name.dhall

let Project = ../Deps/Project.dhall

let Value = ./Value.dhall

let Input = Project.Member

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
      \(config : Algebra.Config) ->
      \(input : Input) ->
        let combine =
              \(name : Name.Output) ->
              \(value : Value.Output) ->
                let fieldName = name.fieldName

                let sig = value.sig

                let fieldType =
                      if input.isNullable then "Option<${sig}>" else sig

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

                in  { fieldName
                    , fieldType
                    , paramFieldDeclaration
                    , columnFieldDeclaration
                    , pgName = input.pgName
                    , paramExpr = "&self.${fieldName}"
                    , pgType = value.pgType
                    , pgCastSuffix = value.pgCastSuffix
                    , supportsDefault
                    }

        in  Lude.Compiled.flatMap
              Name.Output
              Output
              ( \(name : Name.Output) ->
                  Lude.Compiled.map
                    Value.Output
                    Output
                    (\(value : Value.Output) -> combine name value)
                    ( Lude.Compiled.nest
                        Value.Output
                        input.pgName
                        (Value.run config input.value)
                    )
              )
              ( Lude.Compiled.nest
                  Name.Output
                  input.pgName
                  (Name.run config input.name)
              )

in  Algebra.module Input Output run
