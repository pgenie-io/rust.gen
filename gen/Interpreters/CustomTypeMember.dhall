let Deps = ../Deps/package.dhall

let Algebra = ../Algebras/package.dhall

let Sdk = Deps.Sdk

let SharedMember = ./SharedMember.dhall

let Input = SharedMember.Input

let Output = { fieldName : Text, fieldType : Text, pgName : Text }

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        Sdk.Compiled.map
          SharedMember.Output
          Output
          ( \(member : SharedMember.Output) ->
              { fieldName = member.fieldName
              , fieldType = member.fieldType
              , pgName = member.pgName
              }
          )
          (SharedMember.run config input)

in  Algebra.Interpreter.module Input Output run
