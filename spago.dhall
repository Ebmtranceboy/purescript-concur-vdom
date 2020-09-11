{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "my-project"
, dependencies =
  [ "aff"
  , "arrays"
  , "avar"
  , "concur-core"
  , "console"
  , "foldable-traversable"
  , "free"
  , "geometry-plane"
  , "halogen-vdom"
  , "nonempty"
  , "profunctor-lenses"
  , "sparse-polynomials"
  , "tailrec"
  , "web-dom"
  , "web-html"
  ]
, license = "MIT"
, repository = "https://github.com/purescript-concur/purescript-concur-react"
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
