let Deps = ../Deps/package.dhall

let Model = Deps.Sdk.Project

let Letter =
      < A
      | B
      | C
      | D
      | E
      | F
      | G
      | H
      | I
      | J
      | K
      | L
      | M
      | N
      | O
      | P
      | Q
      | R
      | S
      | T
      | U
      | V
      | W
      | X
      | Y
      | Z
      >

let TailElement =
      < Number : Natural | Word : { head : Letter, tail : List Letter } >

let letterIndex =
      \(letter : Letter) ->
        merge
          { A = 0
          , B = 1
          , C = 2
          , D = 3
          , E = 4
          , F = 5
          , G = 6
          , H = 7
          , I = 8
          , J = 9
          , K = 10
          , L = 11
          , M = 12
          , N = 13
          , O = 14
          , P = 15
          , Q = 16
          , R = 17
          , S = 18
          , T = 19
          , U = 20
          , V = 21
          , W = 22
          , X = 23
          , Y = 24
          , Z = 25
          }
          letter

let naturalEq =
      \(left : Natural) ->
      \(right : Natural) ->
            Natural/isZero (Natural/subtract left right)
        &&  Natural/isZero (Natural/subtract right left)

let letterEq =
      \(expected : Letter) ->
      \(actual : Letter) ->
        naturalEq (letterIndex expected) (letterIndex actual)

let wordMatches =
      \(expected : { head : Letter, tail : List Letter }) ->
      \(actual : { head : Letter, tail : List Letter }) ->
        let expectedTailLength = Deps.Prelude.List.length Letter expected.tail

        let actualTailLength = Deps.Prelude.List.length Letter actual.tail

        in      letterEq expected.head actual.head
            &&  naturalEq expectedTailLength actualTailLength
            &&  Deps.Prelude.List.all
                  { index : Natural, value : Letter }
                  ( \(indexedExpected : { index : Natural, value : Letter }) ->
                      merge
                        { None = False
                        , Some =
                            \(actualLetter : Letter) ->
                              letterEq indexedExpected.value actualLetter
                        }
                        ( Deps.Prelude.List.index
                            indexedExpected.index
                            Letter
                            actual.tail
                        )
                  )
                  (Deps.Prelude.List.indexed Letter expected.tail)

let keywordSpecs =
      [ { head = Letter.A
        , tail =
          [ Letter.B
          , Letter.S
          , Letter.T
          , Letter.R
          , Letter.A
          , Letter.C
          , Letter.T
          ]
        }
      , { head = Letter.A, tail = [ Letter.S ] }
      , { head = Letter.A, tail = [ Letter.S, Letter.Y, Letter.N, Letter.C ] }
      , { head = Letter.A, tail = [ Letter.W, Letter.A, Letter.I, Letter.T ] }
      , { head = Letter.B
        , tail = [ Letter.E, Letter.C, Letter.O, Letter.M, Letter.E ]
        }
      , { head = Letter.B, tail = [ Letter.O, Letter.X ] }
      , { head = Letter.B, tail = [ Letter.R, Letter.E, Letter.A, Letter.K ] }
      , { head = Letter.C, tail = [ Letter.O, Letter.N, Letter.S, Letter.T ] }
      , { head = Letter.C
        , tail =
          [ Letter.O
          , Letter.N
          , Letter.T
          , Letter.I
          , Letter.N
          , Letter.U
          , Letter.E
          ]
        }
      , { head = Letter.C, tail = [ Letter.R, Letter.A, Letter.T, Letter.E ] }
      , { head = Letter.D, tail = [ Letter.O ] }
      , { head = Letter.D, tail = [ Letter.Y, Letter.N ] }
      , { head = Letter.E, tail = [ Letter.L, Letter.S, Letter.E ] }
      , { head = Letter.E, tail = [ Letter.N, Letter.U, Letter.M ] }
      , { head = Letter.E
        , tail = [ Letter.X, Letter.T, Letter.E, Letter.R, Letter.N ]
        }
      , { head = Letter.F, tail = [ Letter.A, Letter.L, Letter.S, Letter.E ] }
      , { head = Letter.F, tail = [ Letter.I, Letter.N, Letter.A, Letter.L ] }
      , { head = Letter.F, tail = [ Letter.N ] }
      , { head = Letter.F, tail = [ Letter.O, Letter.R ] }
      , { head = Letter.I, tail = [ Letter.F ] }
      , { head = Letter.I, tail = [ Letter.M, Letter.P, Letter.L ] }
      , { head = Letter.I, tail = [ Letter.N ] }
      , { head = Letter.L, tail = [ Letter.E, Letter.T ] }
      , { head = Letter.L, tail = [ Letter.O, Letter.O, Letter.P ] }
      , { head = Letter.M, tail = [ Letter.A, Letter.C, Letter.R, Letter.O ] }
      , { head = Letter.M, tail = [ Letter.A, Letter.T, Letter.C, Letter.H ] }
      , { head = Letter.M, tail = [ Letter.O, Letter.D ] }
      , { head = Letter.M, tail = [ Letter.O, Letter.V, Letter.E ] }
      , { head = Letter.M, tail = [ Letter.U, Letter.T ] }
      , { head = Letter.O
        , tail =
          [ Letter.V
          , Letter.E
          , Letter.R
          , Letter.R
          , Letter.I
          , Letter.D
          , Letter.E
          ]
        }
      , { head = Letter.P, tail = [ Letter.R, Letter.I, Letter.V ] }
      , { head = Letter.P, tail = [ Letter.U, Letter.B ] }
      , { head = Letter.R, tail = [ Letter.E, Letter.F ] }
      , { head = Letter.R
        , tail = [ Letter.E, Letter.T, Letter.U, Letter.R, Letter.N ]
        }
      , { head = Letter.S, tail = [ Letter.E, Letter.L, Letter.F ] }
      , { head = Letter.S
        , tail = [ Letter.T, Letter.A, Letter.T, Letter.I, Letter.C ]
        }
      , { head = Letter.S
        , tail = [ Letter.T, Letter.R, Letter.U, Letter.C, Letter.T ]
        }
      , { head = Letter.S, tail = [ Letter.U, Letter.P, Letter.E, Letter.R ] }
      , { head = Letter.T, tail = [ Letter.R, Letter.A, Letter.I, Letter.T ] }
      , { head = Letter.T, tail = [ Letter.R, Letter.U, Letter.E ] }
      , { head = Letter.T, tail = [ Letter.Y, Letter.P, Letter.E ] }
      , { head = Letter.T
        , tail = [ Letter.Y, Letter.P, Letter.E, Letter.O, Letter.F ]
        }
      , { head = Letter.T, tail = [ Letter.R, Letter.Y ] }
      , { head = Letter.U, tail = [ Letter.N, Letter.I, Letter.O, Letter.N ] }
      , { head = Letter.U
        , tail = [ Letter.N, Letter.S, Letter.A, Letter.F, Letter.E ]
        }
      , { head = Letter.U, tail = [ Letter.S, Letter.E ] }
      , { head = Letter.U
        , tail = [ Letter.N, Letter.S, Letter.I, Letter.Z, Letter.E, Letter.D ]
        }
      , { head = Letter.V
        , tail = [ Letter.I, Letter.R, Letter.T, Letter.U, Letter.A, Letter.L ]
        }
      , { head = Letter.W, tail = [ Letter.H, Letter.E, Letter.R, Letter.E ] }
      , { head = Letter.W, tail = [ Letter.H, Letter.I, Letter.L, Letter.E ] }
      , { head = Letter.Y, tail = [ Letter.I, Letter.E, Letter.L, Letter.D ] }
      ]

let isRustKeywordName =
      \(name : Model.Name) ->
            naturalEq (Deps.Prelude.List.length TailElement name.tail) 0
        &&  Deps.Prelude.List.any
              { head : Letter, tail : List Letter }
              ( \(keyword : { head : Letter, tail : List Letter }) ->
                  wordMatches keyword name.head
              )
              keywordSpecs

in  { isRustKeywordName }
