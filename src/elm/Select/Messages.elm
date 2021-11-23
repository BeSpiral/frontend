module Select.Messages exposing (Msg(..))


type Msg item
    = NoOp
    | OnFocus
    | OnBlur
    | OnRemoveItem item
    | OnEsc
    | OnDownArrow
    | OnUpArrow
    | OnQueryChange String
    | OnSelect item
