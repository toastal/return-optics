module Return.Optics exposing (refractl, refracto)

{-|
`Return.Optics` is a utility library extending `Return` with
`Monocle` making a clean, concise API for doing Elm component updates
in the context of other updates.


@docs refractl, refracto
-}

import Maybe.Extra as Maybe
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)
import Return exposing (Return, ReturnF)


{-| Refract in a component's update via a `Lens` and a way to merge
the message back along a parent return in the update function.

    Return.singleton model
        |> case msg of
            ...

            MyComponentMsg msg ->
                refractl Model.myComponent MyComponentMsg <|
                    MyComponent.update msg

-}
refractl : Lens a b -> (d -> c) -> (b -> Return d b) -> ReturnF c a
refractl l mergeBack fx ( a, c ) =
    l.get a
        |> fx
        >> Return.mapBoth mergeBack (flip l.set a)
        >> Return.command c


{-| Refract in a component's update via an `Optional` and a way to merge
the message back along a parent return in the update function. If the
getter returns `Nothing` then the `Return` will not be modified.

    Return.singleton model
        |> case msg of
            ...

            MyComponentMsg msg ->
                refracto Model.myComponent MyComponentMsg <|
                    MyComponent.update msg
-}
refracto : Optional a b -> (d -> c) -> (b -> Return d b) -> ReturnF c a
refracto o mergeBack fx (( a, c ) as ret) =
    o.getOption a
        |> Maybe.unwrap ret
            (fx
                >> Return.mapBoth mergeBack (flip o.set a)
                >> Return.command c
            )
