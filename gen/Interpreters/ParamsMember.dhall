let Algebra = ../Algebras/package.dhall

let Lude = ../Deps/Lude.dhall

let Member = ./Member.dhall

let Input = Member.Input

let Output =
      { fieldName : Text
      , fieldType : Text
      , paramFieldDeclaration : Text
      , paramExpr : Text
      , pgType : Text
      , pgCastSuffix : Text
      , supportsDefault : Bool
      }

let run =
      \(config : Algebra.Interpreter.Config) ->
      \(input : Input) ->
        Lude.Compiled.map
          Member.Output
          Output
          ( \(member : Member.Output) ->
              { fieldName = member.fieldName
              , fieldType = member.fieldType
              , paramFieldDeclaration = member.paramFieldDeclaration
              , paramExpr = member.paramExpr
              , pgType = member.pgType
              , pgCastSuffix = member.pgCastSuffix
              , supportsDefault = member.supportsDefault
              }
          )
          (Member.run config input)

in  Algebra.Interpreter.module Input Output run
