module Pages.Users exposing (Params, Model, Msg, page)

import Api.Data exposing (Data)
import Api.User exposing (User, UserWithToken)
import Api.Req exposing (Token)
import Browser.Navigation as Nav exposing (Key)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onSubmit, onInput)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import Shared
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


type ModalMode
    = EditMode User
    | NewMode
    | HideMode

type alias Model =
    { token : Maybe Token
    , users : Data (List User)
    , modalMode : ModalMode
    , username : String
    , password : String
    }



init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    case shared.user of
        Just user ->
            ( Model
                shared.token
                Api.Data.Loading
                HideMode
                ""
                ""
            , fetchUsers shared.token
            )
        Nothing ->
            ( Model Nothing Api.Data.NotAsked NewMode "" ""
            , Nav.pushUrl shared.key (Route.toString Route.SignIn)
            )

-- UPDATE


type Msg
    = GotUsers ( Data ( List User ) )
    | AfterDelete ( Data () )
    | DeleteUser User
    | ModalSubmit
    | UpdateUsername String
    | UpdatePassword String
    | CloseModal
    | OpenModal ModalMode


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUsers users ->
            case Api.Data.toMaybe users of
                Just users_ ->
                    ( { model
                        | users = users
                      }
                    , Cmd.none
                    )
                Nothing ->
                    ( model
                    , Cmd.none
                    )

        AfterDelete _ ->
          ( model
          , fetchUsers model.token
          )

        DeleteUser user ->
            ( model
            , Api.User.delete
                { token = model.token
                , user = { id = user.id }
                , onResponse = AfterDelete 
                }
            )
        UpdateUsername username ->
            ( { model | username = username }
            , Cmd.none
            )

        UpdatePassword password ->
            ( { model | password = password}
            , Cmd.none
            )

        ModalSubmit ->
            ( model
            , Cmd.none
            )
        CloseModal ->
            ( { model | modalMode = HideMode }
            , Cmd.none
            )

        OpenModal mode ->
            ( { model | modalMode = mode }
            , Cmd.none
            )



save : Model -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

fetchUsers : Maybe Api.Req.Token -> Cmd Msg
fetchUsers token =
    Api.User.list
        { token = token
        , onResponse = GotUsers
        }


-- VIEW


view : Model -> Document Msg
view model =
    { title = "Users"
    , body = case Api.Data.toMaybe model.users of
      Just users_ -> 
        [ h2 [] [ text "Users" ]
        , a [ href "#", onClick (OpenModal NewMode) ] [ text "+ Add User" ]
        , table [ class "big-table" ]
          ( List.concat
            [ [ tr []
                [ th [] [ text "Username" ]
                , th [] [ text "Role" ]
                , th [] [ text "Preferred Hours" ]
                , th [] [ text "Action" ]
                ]
              ]
            , (List.map userRow users_)
            ]
          )
        , ( userModal model )
        ]
      Nothing ->
        [ h2 [] [ text "Loading..." ] ]
    }

userRow : User -> Html Msg
userRow user =
    tr []
    [ td [] [ text user.username ]
    , td [] [ text user.role ]
    , td [] [ text ( Maybe.withDefault "" (Maybe.map String.fromInt user.preferredHours) ) ]
    , td []
      [ a [ href "#", onClick ( OpenModal ( EditMode user ) ) ] [ text "Edit" ]
      , text " • "
      , a [ href "#", onClick (DeleteUser user) ] [ text "Delete" ]
      ]
    ]

userModal : Model -> Html Msg
userModal model =
  let
      modalHeader =
         case model.modalMode of
             EditMode _ -> "Edit User"
             NewMode -> "New User"
             _ -> ""

      modalDisplay =
         case model.modalMode of
             HideMode -> "none"
             _ -> "block"
  in
  div [ class "modal", style "display" modalDisplay ]
      [ button [ class "modal-close", onClick CloseModal ] [ text "×" ]
      , h2 [] [ text modalHeader ]
      , Html.form [ onSubmit ModalSubmit ]
        [ viewInput "text" "Username" model.username UpdateUsername
        , viewInput "password" "Password" model.password UpdatePassword
        ]
      ]

viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  input [ type_ t, placeholder p, value v, onInput toMsg ] []
