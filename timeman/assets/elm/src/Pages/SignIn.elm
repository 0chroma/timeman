module Pages.SignIn exposing (Params, Model, Msg, page)

import Api.Data exposing (Data)
import Api.User exposing (UserWithToken)
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
    { userWithToken : Data UserWithToken
    , username : String
    , password : String
    , key : Key
    , invalid : Bool
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    ( Model
        Api.Data.NotAsked
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
    | Submit
    | GotUser (Data UserWithToken)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Username username ->
            ({ model | username = username }, Cmd.none)

        Password password ->
            ({ model | password = password }, Cmd.none)

        Submit ->
            ( model
            , Api.User.authentication
                  { user =
                      { username = model.username
                      , password = model.password
                      }
                  , onResponse = GotUser
                  }
          )
          
        GotUser userWithToken ->
            case Api.Data.toMaybe userWithToken of
                Just userWithToken_ ->
                    ( { model | userWithToken = userWithToken }
                    , Cmd.batch
                        [ Ports.saveUser userWithToken_
                        , (Utils.Route.navigate model.key Route.Top)
                        ]
                    )

                Nothing ->
                    ( { model | userWithToken = userWithToken, invalid = True }
                    , Cmd.none
                    )

save : Model -> Shared.Model -> Shared.Model
save model shared =
    { shared
        | user =
            case Api.Data.toMaybe model.userWithToken of
                Just userWithToken ->
                    Just userWithToken.user

                Nothing ->
                    shared.user
        , token =
            case Api.Data.toMaybe model.userWithToken of
                Just userWithToken ->
                    Just userWithToken.token

                Nothing ->
                    shared.token
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
    { title = "Sign In"
    , body =
        [ Html.form [ class "centered-form", onSubmit Submit]
            [ h2 [] [ text "Sign In"]
            , viewInput "text" "Username" model.username Username
            , viewInput "password" "Password" model.password Password
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
            (not (model.username == "")) && (not (model.password == ""))

        isLength =
          (String.length model.username) >= 5 && (String.length model.password) >= 8

        isDisabled =
          not (isFilled && isLength)

        errorText =
            if model.invalid then
                case model.userWithToken of
                  Api.Data.Failure list ->
                      [ div [ class "error" ] [ text (Maybe.withDefault "" (List.head list)) ] ]
                  _ ->
                      []
            else
                []
    in
    div [] ( List.concat [ errorText, [ button [type_ "submit", class "centered", disabled isDisabled ] [ text "Sign In" ] ] ] )
