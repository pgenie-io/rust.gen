let Algebra = ../Algebras/Interpreter.dhall

let Prelude = ../Deps/Prelude.dhall

let Project = ../Deps/Project.dhall

let Lude = ../Deps/Lude.dhall

let Input = Project.Name

let Output = { fieldName : Text }

let keywordSpecs =
      let Char = Lude.LatinChar.Type

      let a = Char.A

      let b = Char.B

      let c = Char.C

      let d = Char.D

      let e = Char.E

      let f = Char.F

      let g = Char.G

      let h = Char.H

      let i = Char.I

      let j = Char.J

      let k = Char.K

      let l = Char.L

      let m = Char.M

      let n = Char.N

      let o = Char.O

      let p = Char.P

      let q = Char.Q

      let r = Char.R

      let s = Char.S

      let t = Char.T

      let u = Char.U

      let v = Char.V

      let w = Char.W

      let x = Char.X

      let y = Char.Y

      let z = Char.Z

      let words =
            [ [ a, b, s, t, r, a, c, t ]
            , [ a, s ]
            , [ a, s, y, n, c ]
            , [ a, w, a, i, t ]
            , [ b, e, c, o, m, e ]
            , [ b, o, x ]
            , [ b, r, e, a, k ]
            , [ c, o, n, s, t ]
            , [ c, o, n, t, i, n, u, e ]
            , [ c, r, a, t, e ]
            , [ d, o ]
            , [ d, y, n ]
            , [ e, l, s, e ]
            , [ e, n, u, m ]
            , [ e, x, t, e, r, n ]
            , [ f, a, l, s, e ]
            , [ f, i, n, a, l ]
            , [ f, n ]
            , [ f, o, r ]
            , [ i, f ]
            , [ i, m, p, l ]
            , [ i, n ]
            , [ l, e, t ]
            , [ l, o, o, p ]
            , [ m, a, c, r, o ]
            , [ m, a, t, c, h ]
            , [ m, o, d ]
            , [ m, o, v, e ]
            , [ m, u, t ]
            , [ o, v, e, r, r, i, d, e ]
            , [ p, r, i, v ]
            , [ p, u, b ]
            , [ r, e, f ]
            , [ r, e, t, u, r, n ]
            , [ s, e, l, f ]
            , [ s, t, a, t, i, c ]
            , [ s, t, r, u, c, t ]
            , [ s, u, p, e, r ]
            , [ t, r, a, i, t ]
            , [ t, r, u, e ]
            , [ t, y, p, e ]
            , [ t, y, p, e, o, f ]
            , [ t, r, y ]
            , [ u, n, i, o, n ]
            , [ u, n, s, a, f, e ]
            , [ u, s, e ]
            , [ u, n, s, i, z, e, d ]
            , [ v, i, r, t, u, a, l ]
            , [ w, h, e, r, e ]
            , [ w, h, i, l, e ]
            , [ y, i, e, l, d ]
            ]

      let words = [] : List (List Lude.LatinChar.Type)

      in  Prelude.List.mapMaybe
            (List Char)
            Lude.LatinChars.Type
            (Lude.List.uncons Char)
            words

let isRustKeyword =
      \(name : Project.Name) ->
            Prelude.List.null Project.LatinWordOrNumber name.tail
        &&  Lude.List.elem
              Lude.LatinChars.Type
              Lude.LatinChars.equality
              name.head
              keywordSpecs

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        let rawFieldName = Lude.Name.toTextInSnake input

        let fieldName =
              if isRustKeyword input then rawFieldName ++ "_" else rawFieldName

        in  Lude.Compiled.ok Output { fieldName }

in  Algebra.module Input Output run
