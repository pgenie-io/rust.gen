let Deps = ../Deps/package.dhall

let Algebra = ../Algebras/package.dhall

let Sdk = Deps.Sdk

let SharedMember = ./SharedMember.dhall

let Input = SharedMember.Input

let Output =
      { fieldName : Text
      , fieldType : Text
      , paramFieldDeclaration : Text
      , paramExpr : Text
      , pgType : Text
      , pgCastSuffix : Text
      }

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        Sdk.Compiled.map
          SharedMember.Output
          Output
          ( \(member : SharedMember.Output) ->
              { fieldName = member.fieldName
              , fieldType = member.fieldType
              , paramFieldDeclaration = member.paramFieldDeclaration
              , paramExpr = member.paramExpr
              , pgType = member.pgType
              , pgCastSuffix = member.pgCastSuffix
              }
          )
          (SharedMember.run config input)

in  Algebra.Interpreter.module Input Output run
