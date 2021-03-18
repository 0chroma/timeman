module Shared exposing
    ( Flags
    , Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Api.User exposing (User)
import Browser.Navigation exposing (Key)
import Html exposing (..)
import Html.Attributes exposing (class, href)
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
    }


init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    let
        user =
            flags
                |> Json.decodeValue (Json.field "user" Api.User.decoder)
                |> Result.toMaybe
    in
        ( Model url key user
        , Cmd.none
        )



-- UPDATE


type Msg
    = SignedOutUser
    | SignedInUser User

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SignedInUser user ->
            ( { model | user = Just user }
            , Ports.saveUser user
            )

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
    { title = page.title
    , body =
        [ div [ class "layout" ]
            [ header [ class "navbar" ]
                [ a [ class "link", href (Route.toString Route.Top) ] [ text "Homepage" ]
                , a [ class "link", href (Route.toString Route.SignIn) ] [ text "Sign In" ]
                , span [ class "account"]
                  [ a [ class "link", href (Route.toString Route.SignIn) ] [ text "Sign In" ]
                  ]
                ]
            , div [ class "page" ] page.body
            ]
        ]
    }
