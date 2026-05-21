let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Member = ./Member.dhall

let Templates = ../Templates/package.dhall

let Input = Member.Input

let Output =
      { fieldName : Text, fieldType : Text, columnFieldDeclaration : Text }

let run =
      \(config : Algebra.Interpreter.Config) ->
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
              }
          )
          (Member.run config input)

in  Algebra.Interpreter.module Input Output run
