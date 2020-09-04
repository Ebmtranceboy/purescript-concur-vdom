module Concur.VDom.Props where

import Prelude

import Concur.Core.Props (Props(..))
import Concur.VDom.Props.Internal as P
import Data.Newtype (wrap)
import Effect.Uncurried (mkEffectFn1)
import Web.Event.Event as DOM
import Web.HTML.HTMLInputElement (fromElement, value) as Input
import Web.DOM.Element (fromEventTarget, toNode)
import Web.DOM.Node (textContent)
import Effect.Unsafe (unsafePerformEffect)
import Data.Maybe (Maybe(..), maybe)

type VDomProps a = Props P.Prop a

-- | Construct a custom prop handler
handle :: String -> VDomProps DOM.Event
handle s = Handler \f -> P.Handler (wrap s) (mkEffectFn1 f)

-- | Construct a custom key value prop
prop :: forall a b. String -> a -> VDomProps b
prop s v = PrimProp (P.Property s (P.propValue v))

onClick :: Props P.Prop DOM.Event
onClick = handle "click"

onChange :: Props P.Prop DOM.Event
onChange = handle "input"

onFocus :: Props P.Prop DOM.Event
onFocus = handle "focus"

onMouseMove :: Props P.Prop DOM.Event
onMouseMove = handle "mousemove"

onMouseDown :: Props P.Prop DOM.Event
onMouseDown = handle "mousedown"

onMouseUp :: Props P.Prop DOM.Event
onMouseUp = handle "mouseup"

unsafeTargetValue :: DOM.Event -> String
unsafeTargetValue ev = 
  unsafePerformEffect 
    $ maybe (pure "") Input.value 
    $ Input.fromElement =<< fromEventTarget =<< DOM.target ev

unsafeTextContent :: DOM.Event -> String
unsafeTextContent ev = 
  unsafePerformEffect 
    $ maybe (pure "") textContent 
    $ (Just <<< toNode) =<< fromEventTarget =<< DOM.target ev

_type :: forall a. String -> Props P.Prop a
_type = prop "type"

value :: forall a. String -> Props P.Prop a
value = prop "value"

checked :: forall a. Boolean -> Props P.Prop a
checked = prop "checked"

dangerouslySetInnerHTML :: forall a. String -> Props P.Prop a
dangerouslySetInnerHTML = prop "innerHTML"

-- | Construct a custom key value attribute
attr :: forall a. String -> String -> VDomProps a
attr s v = PrimProp (P.Attribute Nothing s v)

