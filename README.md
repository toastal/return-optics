# Return.Optics

`Return.Optics` is a utility library extending `Return` with `Monocle` making a clean, concise <abbr title="application programming interface">API</abbr> for doing Elm component updates in the context of other updates. Initially it includes helper functions around refraction—the bending of light. Like viewing a straw being inserted into a glass of water, we’ll use a `Lens` to bend our top-level update function into our component update, and when we pull it out, well be left with an unbent `( model, Cmd msg )` of the Elm architecture.

If you would like a more in-depth read into why, you can read about that on [my blog](https://toast.al/posts/2016-10-20-optical-swordplay-with-components.html).

However, if that’s not your thing and doesn’t make sense, you’re in luck because we’re about to go over an example.

Suppose we have this trivial, toy component and model…


#### Models

```elm
module Model exposing (Model)

import Checkbox.Model as Checkbox


type alias Model =
    { pageTitle : String
    , checkbox : Checkbox.Model
    }
```

```elm
module Checkbox.Model exposing (Model)

type alias Model =
    { checked : Bool
    }
```


#### Msgs

```elm
module Msg exposing (Msg(..))

import Checkbox.Msg as Checkbox


type Msg
    = TitleChange String
    | CheckboxMsg Checkbox.Msg
```

```elm
module Checkbox.Msg exposing (Msg(..))

type Checkbox
    = CheckMe Bool
```


Assuming we have built up some `cmdWeAlwaysDo`, with the standard library we’d write updates like this:


#### Stardard Updates

```elm
module Update exposing (update)

import Checkbox.Update as Checkbox
import Model
import Msg exposing (Msg(TitleChange, CheckboxMsg))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        cmdWeAlwaysDo : Cmd Msg
        cmdWeAlwaysDo =
            -- insert a real command in a non-toy app
            Cmd.none
    in
        case msg of
            TitleChange title ->
                ( { model | pageTitle = title }, cmdWeAlwaysDo )

            CheckboxMsg cbMsg ->
                let
                    ( cbModel, cbCmd )
                        Checkbox.Update cbMsg model.checkbox
                in
                    { model | checkbox = cbModel }
                        ! [ cbCmd
                          , cmdWeAlwaysDo
                          ]
```

```elm
module Checkbox.Update exposing (update)

import Checkbox.Model as Model
import Checkbox.Msg as Msg exposing (Msg(CheckMe))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CheckMe bool ->
            { model | checked = bool }
```


- - -


Using `Return.Optics.refractl` and `Lens`es we can instead change our model files and our update files like this:

```elm
module Model exposing (..)

import Monocle.Lens exposing (Lens)
import Checkbox.Model as Checkbox


type alias Model =
    { pageTitle : String
    , checkbox : Checkbox.Model
    }


pageTitle : Lens Model String
pageTitle =
    Lens .pageTitle <| \p m -> { m | pageTitle = p }


checkbox : Lens Model Checkbox.Model
checkbox =
    Lens .checkbox <| \c m -> { m | checkbox = c }
```

```elm
module Checkbox.Model exposing (..)

import Monocle.Lens exposing (Lens)


type alias Model =
    { checked : Bool
    }


checked : Lens Model Bool
checked =
    Lens .checked <| \c m -> { m | checked = c }
```

```elm
module Update exposing (update)

import Return exposing (Return)
import Return.Optics exposing (refractl)
import Checkbox.Update as Checkbox
import Model
import Msg exposing (Msg(TitleChange, CheckboxMsg))


update : Msg -> Model -> Return Msg Cmd
update msg model =
    let
        cmdWeAlwaysDo : Cmd Msg
        cmdWeAlwaysDo =
            -- insert a real command in a non-toy app
            Cmd.none
    in
        Return.singleton model
            |> Return.command cmdWeAlwaysDo
            |> case msg of
                TitleChange title ->
                    Return.map <| .set Model.pageTitle title

                -- Note how much more condensed this part is
                CheckboxMsg cbMsg ->
                    refractl Model.checkbox CheckboxMsg <|
                      Checkbox.update cbMsg
```

```elm
module Checkbox.Update exposing (update)

import Checkbox.Model as Model
import Checkbox.Msg as Msg exposing (Msg(..))


update : Msg -> Model -> Return Msg Model
update msg model =
    Return.singleton model
        |> case msg of
            CheckMe bool ->
                Return.map <| .set Model.checked = bool
```


