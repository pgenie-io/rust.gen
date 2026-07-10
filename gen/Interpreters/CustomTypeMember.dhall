let Sdk = ../Deps/Sdk.dhall

let ResolvedTarget = ../ResolvedTarget.dhall

let Lude = ../Deps/Lude.dhall

let Member = ./Member.dhall

let Input = Member.Input

let Output = { fieldName : Text, fieldType : Text, pgName : Text }

let run =
      \(config : ResolvedTarget.Type) ->
      \(input : Input) ->
        Lude.Compiled.map
          Member.Output
          Output
          ( \(member : Member.Output) ->
              { fieldName = member.fieldName
              , fieldType = member.fieldType
              , pgName = member.pgName
              }
          )
          (Member.run config input)

in  Sdk.Sigs.Interpreter.module ResolvedTarget.Type Input Output run
