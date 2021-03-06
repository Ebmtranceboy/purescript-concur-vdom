module Concur.VDom.DOM where

import Prelude hiding (div,map,sub)

import Concur.Core.DOM as CD
import Concur.Core.LiftWidget (class LiftWidget, liftWidget)
import Concur.Core.Props (Props)
import Concur.Core.Types (Widget, display)
import Concur.Thunk.Internal (thunk1)
import Concur.VDom.Props (VDomProps)
import Concur.VDom.Props.Internal as P
import Concur.VDom.Types (HTML, HTMLNode, mkHTMLNode, unHTML, unKeyedHTML)
import Control.MultiAlternative (class MultiAlternative)
import Control.ShiftMap (class ShiftMap)
import Data.Function.Uncurried as Fn
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple)
import Halogen.VDom.Types as D

-- | The VDom backend uses Array to make view monoidal
-- | We use this view adapter to derive our specialised `el` functions
viewAdapter
  :: forall ps vs res
  .  (ps -> vs -> res)
  -> (ps -> vs -> Array res)
viewAdapter f = \ps vs -> [f ps vs]

el
  :: forall m a p v
  .  ShiftMap (Widget (Array v)) m
  => (Array p -> Array v -> v)
  -> Array (Props p a)
  -> m a
  -> m a
el f = CD.el (viewAdapter f)

el'
  :: forall m a p v
  .  ShiftMap (Widget (Array v)) m
  => MultiAlternative m
  => (Array p -> Array v -> v)
  -> Array (Props p a)
  -> Array (m a)
  -> m a
el' f = CD.el' (viewAdapter f)

elLeaf
  :: forall p v m a
  .  LiftWidget (Array v) m
  => (Array p -> v)
  -> Array (Props p a)
  -> m a
elLeaf f = CD.elLeaf (\ps -> [f ps])

type El1
  = forall m a. ShiftMap (Widget HTML) m => Array (VDomProps a) -> m a -> m a

type El
  = forall m a. MultiAlternative m => ShiftMap (Widget HTML) m => Array (VDomProps a) -> Array (m a) -> m a

type El'
  = forall m a. MultiAlternative m => ShiftMap (Widget HTML) m => Array (m a) -> m a

type ElLeaf
  = forall m a. LiftWidget HTML m => Array (VDomProps a) -> m a

type ElLeaf'
  = forall m a. LiftWidget HTML m => m a

type ElLeafFunc' x
  = forall m a. LiftWidget HTML m => x -> m a


-------------------------------------------------------------------------------------------------------------------
text :: ElLeafFunc' String
text str = liftWidget wid
  where
    wid :: forall a. Widget HTML a
    wid = display [mkHTMLNode $ D.Text str]

-- node_ :: forall m a. ShiftMap (Widget HTML) m => String -> Array (VDomProps a) -> m a -> m a
node_ :: String -> El1
node_ s = el (nodeBuilder s)

-- node :: forall m a. MultiAlternative m => ShiftMap (Widget HTML) m => String -> Array P.Prop -> Array (m a) -> m a
node :: String -> El
node s = el' (nodeBuilder s)

node' :: String -> El'
node' s = node s []

-- TODO: Keyed
-- keyed_ :: forall m a. ShiftMap (Widget HTML) m => String -> Array (VDomProps a) -> m a -> m a
-- keyed_ :: String -> El1
-- keyed_ s = el (keyedNodeBuilder s)
-- keyed :: forall m a. MultiAlternative m => ShiftMap (Widget HTML) m => String -> Array P.Prop -> Array (m a) -> m a
-- keyed :: String -> _
-- keyed s = el' (keyedNodeBuilder s)
-- keyed' :: String -> El'
-- keyed' s = keyed s []

-- TODO: Thunks


-- Internal
nodeBuilder :: String -> Array P.Prop -> HTML -> HTMLNode
nodeBuilder s prop c = mkHTMLNode $ D.Elem Nothing (D.ElemName s) prop (unHTML c)

keyedNodeBuilder :: String → Array P.Prop -> Array (Tuple String HTMLNode) → HTMLNode
keyedNodeBuilder s prop c = mkHTMLNode $ D.Keyed Nothing (D.ElemName s) prop (unKeyedHTML c)

thunkBuilder :: forall a. (a -> HTMLNode) -> a -> HTMLNode
thunkBuilder render val = mkHTMLNode $ D.Widget $ Fn.runFn2 thunk1 render val

div :: El
div = node "div"

div' :: El'
div' = node' "div"

div_ :: El1
div_ = node_ "div"

h1 :: El
h1 = node "h1"

h1_ :: El1
h1_ = node_ "h1"

h2 :: El
h2 = node "h2"

h2_ :: El1
h2_ = node_ "h2"

h3 :: El
h3 = node "h3"

h3_ :: El1
h3_ = node_ "h3"

h4 :: El
h4 = node "h4"

h4_ :: El1
h4_ = node_ "h4"

em :: El
em = node "em"

b :: El
b = node "b"

br :: El
br = node "br"

p :: El
p = node "p"

p' :: El'
p' = node' "p"

label :: El
label = node "label"

label' :: El'
label' = node' "label"

pre :: El'
pre = node' "pre"

ul :: El
ul = node "ul"

li :: El
li = node "li"


type Leaf m a = forall m a. MultiAlternative m => ShiftMap (Widget HTML) m => Array (Props P.Prop a) -> m a

hr :: forall m a. Leaf m a
hr ps = node "hr" ps []

hr' :: forall m a. MultiAlternative m => ShiftMap (Widget HTML) m => m a
hr' = hr []

button :: El
button = node "button"

button' :: El'
button' = node' "button"

input :: forall m a. Leaf m a
input ps = node "input" ps []
