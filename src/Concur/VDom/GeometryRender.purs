module Concur.VDom.GeometryRender where

import Prelude
import Concur.Core (Widget)
import Concur.VDom (HTML)
import Concur.VDom.DOM as D
import Concur.VDom.SVG as S
import Data.Geometry.Plane (Arc(..), Circle(..), HalfLine(..) , Line
                    , Point(..), RightAngle(..), Segment(..), Vector(..)
                    , aPointOnLine, aVectorOfLine, abs, halfline
                    , length, middle, normalTo, ord, rotated, scale
                    , segment, vector, (<+|))
import Data.Enum(toEnum)
import Data.Array (concat)
import Data.Int (round)
import Data.String(singleton)
import Data.Maybe(Maybe(..),maybe,fromJust)
import Partial.Unsafe(unsafePartial)
import Data.Sparse.Polynomial((^))
import Math (atan2, pi)

type Color = String 
type FontStyle = String
type Position = Number
type Size = Number
type Path = String

line :: forall a. Position -> Position 
               -> Position -> Position 
               -> Color -> Size -> Widget HTML a
line x1 y1 x2 y2 color size =
 S.line
    [ S.unsafeMkProp "x1" $ round x1
    , S.unsafeMkProp "x2" $ round x2
    , S.unsafeMkProp "y1" $ round y1
    , S.unsafeMkProp "y2" $ round y2
    , S.stroke color
    , S.strokeWidth $ round size
    ]
    []
    
text :: forall a. Position -> Position 
               -> Color -> FontStyle 
               -> String -> Widget HTML a
text x y color fontStyle str = 
  S.text [ S.unsafeMkProp "x" $ round x 
         , S.unsafeMkProp "y" $ round y
         , S.style $ "fill:" <> color <> "; font:" <> fontStyle <> "; "
         ] [D.text str]     
                   
path :: forall a. Color -> Size
                  -> Color 
                  -> Path -> Widget HTML a
path stroke strokeWidth fill content = 
  S.path 
    [ S.d content
    , S.style $ "stroke:" <> stroke
                            <> "; stroke-width:" <> (show $ round strokeWidth)
                            <> "; fill:" <> fill <> ";"
    ]
    []
    
type Context = 
   { stroke :: Color
   , fill :: Color
   , strokeWidth :: Size
   , fontStyle :: FontStyle
   , textFill :: Color}

defaultContext :: Context
defaultContext = 
  { stroke: "#000"
  , fill: "#00000000"
  , strokeWidth: 1.5
  , fontStyle: "italic 15px sans-serif"
  , textFill: "#000"
  }

class Render geo where
  render' :: forall a. Context -> geo -> Array (Widget HTML a)

instance renderPoint :: Render Point where
  render' {stroke, strokeWidth, textFill, fontStyle} 
           p@(Point {name, coordinates}) = 
    [ line (abs p - 5.0) (ord p - 5.0)
         (abs p + 5.0) (ord p + 5.0) 
         stroke strokeWidth
    , line (abs p - 5.0) (ord p + 5.0)
         (abs p + 5.0) (ord p - 5.0)
         stroke strokeWidth
    , text (abs p + 10.0) (ord p - 10.0) 
         textFill fontStyle 
         name
    ]

instance renderHalfLine :: Render HalfLine where
  render' {stroke, strokeWidth} 
           (HalfLine {origin, direction}) = 
    let far = origin <+| scale 10.0 direction
    in [ line (abs origin) (ord origin) 
            (abs far) (ord far) 
            stroke strokeWidth
       ]

instance renderLine :: Render Line where
  render' ctx l = 
    let m = aPointOnLine l
        v = aVectorOfLine l
     in    (render' ctx $ halfline m v)
        <> (render' ctx $ halfline m (scale (-1.0) v))

arrowBluntness = 0.2 :: Number
arrowLength = 20.0 :: Number

arrowTip :: Segment -> {at1 :: Point, at2 :: Point}
arrowTip s@(Segment {origin, extremity, asOriented}) = 
  let v = vector origin extremity
      ang = atan2 (ord v) (abs v)
      v0 = Vector $ (length v)^0
      f theta = 
        let v1 = rotated theta $ Vector $ arrowLength^0
          in origin <+| (rotated ang $ v1 <+| v0)
   in { at1: f (pi - arrowBluntness)
      , at2: f (pi + arrowBluntness)}

pathCoord :: Point -> String
pathCoord p = " " <> (show $ abs p) <> " " <> (show $ ord p) <> " "

instance renderSegment :: Render Segment where
  render' {stroke, strokeWidth, fontStyle, textFill} 
           s@(Segment {origin,extremity,asOriented}) = 
    let m = middle "" s
    in [ line (abs origin) (ord origin)
         (abs extremity) (ord extremity)
         stroke strokeWidth
       ]
        <> ( maybe [] (\str -> 
                let {at1, at2} = arrowTip s
                in [ path stroke strokeWidth stroke $
                       "M" <> pathCoord at1
                    <> "L" <> pathCoord extremity
                    <> "L" <> pathCoord at2 <> "Z" 
                   ] ) asOriented
           )
        <> ( maybe [] (\str -> 
            [ text (abs m + 10.0) (ord m - 10.0) 
                 textFill fontStyle
                 str
            , text (abs m + 10.0) (ord m - 23.0) 
                 textFill fontStyle 
                       (if str=="" 
                          then "" 
                          else singleton $ unsafePartial 
                                         $ fromJust 
                                         $ toEnum 0x2192)
           ] ) asOriented
          )

instance renderCircle :: Render Circle where
  render' {stroke, strokeWidth, fill} 
           (Circle{center: c,radius}) = 
    [ path stroke strokeWidth fill $
            "M " <> (show $ abs c - radius) <> " " <> (show $ ord c) <> " "
         <> "a " <> (show radius) <> " " <> (show radius) <> " "
                 <> "0 1 0 " <> (show $ 2.0 * radius) <> " 0" 
    , path stroke strokeWidth fill $
            "M " <> (show $ abs c - radius) <> " " <> (show $ ord c) <> " "
         <> "a " <> (show radius) <> " " <> (show radius) <> " "
                 <> "0 1 1 " <> (show $ 2.0 * radius) <> " 0" 
    ]

instance renderArc :: Render Arc where
  render' {stroke, strokeWidth, fill, fontStyle, textFill} 
         (Arc { origin, center, extremity, radius
              , flag, flipped, swapped, asOriented}) = 
    let u = scale (radius / length origin) origin
        pO = center <+| u 
        v = scale (radius / length extremity) extremity
        pE = center <+| v
        a2 = if flipped then "0 " else "1 "
        b = if flipped && swapped then not flag else flag
        a1 = if b then "1 " else "0 "
        a3 = if b then 1.0 else -1.0
        n = pE <+| (scale (-a3) $ normalTo extremity)
        {at1, at2} = arrowTip $ segment n pE Nothing
        uv = u <+| v
        i = center <+| scale (radius * 0.8 / length uv) uv
         
     in  [ path stroke strokeWidth fill $
                "M" <> pathCoord pO
             <> "a " <> show radius <> " " <> show radius <> " "
             <> "0 " <> a1 <> a2 <> " "
             <> (show $ abs pE - abs pO) <> " " 
             <> (show $ ord pE - ord pO)
          ] 
           <>     
          (maybe [] (\str ->
                 [ path stroke strokeWidth stroke $
                        "M" <> pathCoord at2
                    <> "L" <> pathCoord pE
                    <> "L" <> pathCoord at1 <> "Z"] ) asOriented)
           <>
           (maybe [] (\str -> 
                  [text (abs i) (ord i) 
                     textFill fontStyle
                     str]) asOriented)

instance renderRightAngle :: Render RightAngle where
  render' {stroke, strokeWidth, fill} 
         (RightAngle {origin, center, extremity, radius}) = 
    let v = scale (radius/length extremity) extremity
        w = scale (radius/length origin) origin
        u = v <+| w
        m = center <+| u
        n = center <+| v
        o = center <+| w
       in [ path stroke strokeWidth fill $
             "M" <> pathCoord o
          <> "L" <> pathCoord m
          <> "L" <> pathCoord n
          ]
  
instance renderSequence :: Render a => Render (Array a) where        
  render' ctx arr = concat $ (render' ctx) <$> arr

