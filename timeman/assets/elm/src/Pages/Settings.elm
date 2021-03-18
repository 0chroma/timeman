module Pages.Settings exposing (Params, Model, Msg, page)

import Api.Data exposing (Data)
import Api.User exposing (User, UserWithToken)
import Api.Req exposing (Token)
import Browser.Navigation as Nav exposing (Key)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import Shared
import Ports
import Utils.Route

page : Page Params Model Msg
page =
    Page.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }



-- INIT


type alias Params =
    ()


type alias Model =
    { user : Data User
    , token : Maybe Token
    , username : String
    , password : String
    , passwordAgain : String
    , preferredHours : Maybe Int
    , userId : Int
    , invalid : Bool
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    case shared.user of
        Just user ->
            ( Model
                (Api.Data.Success user)
                shared.token
                user.username
                ""
                ""
                user.preferredHours
                user.id
                False
            , Cmd.none
            )
        Nothing ->
            ( Model Api.Data.NotAsked shared.token "" "" "" Nothing 0 False
            , Nav.pushUrl shared.key (Route.toString Route.SignIn)
            )



-- UPDATE


type Msg
    = Username String
    | Password String
    | PasswordAgain String
    | PreferredHours String
    | Submit
    | GotUser (Data User)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Username username ->
            ({ model | username = username }, Cmd.none)

        Password password ->
            ({ model | password = password }, Cmd.none)

        PasswordAgain password ->
            ({ model | passwordAgain = password }, Cmd.none)

        PreferredHours preferredHours ->
            ({ model | preferredHours = String.toInt preferredHours }, Cmd.none)

        Submit ->
            let
                password =
                    case model.password of
                      "" -> Nothing
                      pw -> Just pw
            in
            ( model
            , Api.User.update
                  { user =
                      { id = model.userId
                      , username = Just model.username
                      , password = password
                      , role = Nothing
                      , preferredHours = model.preferredHours
                      }
                  , token = model.token
                  , onResponse = GotUser
                  }
          )
          
        GotUser user ->
            case Maybe.map2 (\user_ token -> UserWithToken user_ token) (Api.Data.toMaybe user) model.token of
                Just userWithToken ->
                    
                    ( { model | user = user }
                    , Ports.saveUser userWithToken
                    )

                Nothing ->
                    ( { model | user = user, invalid = True }
                    , Cmd.none
                    )

save : Model -> Shared.Model -> Shared.Model
save model shared =
    { shared
        | user =
            case Api.Data.toMaybe model.user of
                Just user ->
                    Just user

                Nothing ->
                    shared.user
    }


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Settings"
    , body =
        [ Html.form [ class "centered-form", onSubmit Submit]
            [ h2 [] [ text "Settings"]
            , viewInput "text" "Username" model.username Username
            , viewInput "password" "Password" model.password Password
            , input
                [type_ "number"
                , placeholder "Preferred Hours"
                , value ( String.fromInt ( Maybe.withDefault 1 model.preferredHours ) )
                , onInput PreferredHours
                , Html.Attributes.min "1"
                , Html.Attributes.max "24"] []
            , viewValidation model
            ]
        ]
    }

viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  input [ type_ t, placeholder p, value v, onInput toMsg ] []

viewValidation : Model -> Html msg
viewValidation model =
    let 
        isFilled =
            (not (model.username == ""))
        isLength =
          (String.length model.username) >= 5
        isDisabled =
          not (isFilled && isLength)

        errorText =
            if model.invalid then
                case model.user of
                  Api.Data.Failure list ->
                      Maybe.withDefault "" (List.head list)
                  _ ->
                      ""
            else
                ""
    in
    div []
        [ div [ class "error" ] [ text errorText ]
        , button [type_ "submit", class "centered", disabled isDisabled ] [ text "Save" ]
        ]
