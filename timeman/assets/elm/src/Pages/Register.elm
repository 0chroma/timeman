module Pages.Register exposing (Params, Model, Msg, page)

import Api.Data exposing (Data)
import Api.User exposing (User)
import Browser.Navigation exposing (Key)
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
    , username : String
    , password : String
    , passwordAgain : String
    , key : Key
    , invalid : Bool
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    ( Model
        (case shared.user of
            Just user ->
                Api.Data.Success user

            Nothing ->
                Api.Data.NotAsked
        )
        ""
        ""
        ""
        shared.key
        False
    , Cmd.none
    )



-- UPDATE


type Msg
    = Username String
    | Password String
    | PasswordAgain String
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

        Submit ->
            ( model
            , Api.User.registration
                  { user =
                      { username = model.username
                      , password = model.password
                      , role = Nothing
                      }
                  , onResponse = GotUser
                  }
          )
          
        GotUser user ->
            case Api.Data.toMaybe user of
                Just user_ ->
                    ( { model | user = user }
                    , Cmd.batch
                        [ Ports.saveUser user_ 
                        , (Utils.Route.navigate model.key Route.Top)
                        ]
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
    { title = "Register"
    , body =
        [ Html.form [ class "centered-form", onSubmit Submit]
            [ h2 [] [ text "Register"]
            , viewInput "text" "Username" model.username Username
            , viewInput "password" "Password" model.password Password
            , viewInput "password" "Confirm Password" model.passwordAgain PasswordAgain
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
        isPasswordMatching =
            model.password == model.passwordAgain

        isUsernameLength =
            (String.length model.username) >= 5

        isPasswordLength =
            (String.length model.password) >= 8

        isDisabled =
             not (isUsernameLength && isPasswordLength && isPasswordMatching)

        errorText =
            if not isUsernameLength && not (model.username == "") then
                "Username too short"
            else if not isPasswordLength && not (model.password == "") then
                "Password too short"
            else if not isPasswordMatching then
                "Passwords don't match"
            else if model.invalid then
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
        , button [type_ "submit", class "centered", disabled isDisabled ] [ text "Register" ]
        ]
