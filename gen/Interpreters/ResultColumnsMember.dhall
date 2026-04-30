let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Member = ./Member.dhall

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
              , columnFieldDeclaration = member.columnFieldDeclaration
              }
          )
          (Member.run config input)

in  Algebra.Interpreter.module Input Output run
