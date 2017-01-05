module Return.Optics exposing (refractl, refracto)

{-|
`Return.Optics` is a utility library extending `Return` with
`Monocle` making a clean, concise API for doing Elm component updates
in the context of other updates.

It the signatures

- `pmod` is Parent Model
- `pmsg` is Parent Msg
- `cmod` is Child Model
- `cmsg` is Child Msg


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
refractl : Lens pmod cmod -> (cmsg -> pmsg) -> (cmod -> Return cmsg cmod) -> ReturnF pmsg pmod
refractl lens mergeBack fx ( model, cmd ) =
    lens.get model
        |> fx
        |> Return.mapBoth mergeBack (flip lens.set model)
        |> Return.command cmd


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
refracto : Optional pmod cmod -> (cmsg -> pmsg) -> (cmod -> Return cmsg cmod) -> ReturnF pmsg pmod
refracto opt mergeBack fx (( model, cmd ) as return) =
    opt.getOption model
        |> Maybe.unwrap return
            (fx
                >> Return.mapBoth mergeBack (flip opt.set model)
                >> Return.command cmd
            )
