module Shared exposing
    ( Flags
    , Model
    , Msg(..)
    , init
    , subscriptions
    , update
    , view
    )

import Api.User exposing (User, UserWithToken)
import Api.Req exposing (Token)
import Browser.Navigation exposing (Key)
import Html exposing (..)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Json.Decode as Json
import Ports
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Url exposing (Url)

-- INIT


type alias Flags =
    Json.Value


type alias Model =
    { url : Url
    , key : Key
    , user : Maybe User
    , token : Maybe Token
    }


init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    let
        userWithToken =
            flags
                |> Json.decodeValue (Json.field "user" Api.User.userWithTokenDecoder)
                |> Result.toMaybe
    in
        ( Model
            url
            key
            ( Maybe.map (\uwt -> uwt.user) userWithToken )
            ( Maybe.map (\uwt -> uwt.token) userWithToken )
        , Cmd.none
        )



-- UPDATE


type Msg
    = SignedOutUser

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SignedOutUser ->
            ( { model | user = Nothing }
            , Ports.clearUser
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view :
    { page : Document msg, toMsg : Msg -> msg }
    -> Model
    -> Document msg
view { page, toMsg } model =
    { title = page.title ++ "- Time Management"
    , body =
        [ div [ class "layout" ]
            [ header [ class "navbar" ]
                [ a [ href (Route.toString Route.Top) ] [ text "Entries" ]
                , accountDetailsView toMsg model.user
                ]
            ]
            , div [ class "page" ] page.body
        ]
    }

accountDetailsView toMsg maybeUser =
    case maybeUser of
        Just user ->
            span [ class "account"]
            [ a [ href (Route.toString Route.Settings) ] [ text user.username ]
            , a [ href (Route.toString Route.SignIn), onClick (toMsg SignedOutUser)] [ text "Sign Out" ]
            ]

        Nothing ->
            span [ class "account"]
            [ a [ href (Route.toString Route.SignIn) ] [ text "Sign In" ]
            , a [ href (Route.toString Route.Register) ] [ text "Register" ]
            ]

