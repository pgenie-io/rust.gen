let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let SharedMember = ./SharedMember.dhall

let Input = SharedMember.Input

let Output =
      { fieldName : Text, fieldType : Text, columnFieldDeclaration : Text }

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        Lude.Compiled.map
          SharedMember.Output
          Output
          ( \(member : SharedMember.Output) ->
              { fieldName = member.fieldName
              , fieldType = member.fieldType
              , columnFieldDeclaration = member.columnFieldDeclaration
              }
          )
          (SharedMember.run config input)

in  Algebra.Interpreter.module Input Output run
