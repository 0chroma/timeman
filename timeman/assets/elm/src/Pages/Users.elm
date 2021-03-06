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
    , key : Key
    , users : Data (List User)
    , modalMode : ModalMode
    , modalResponse : Data User
    , username : String
    , password : String
    , role: String
    , preferredHours: Maybe Int
    }



init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    case shared.user of
        Just user ->
            ( Model
                shared.token
                shared.key
                Api.Data.Loading
                HideMode
                Api.Data.NotAsked
                ""
                ""
                ""
                Nothing
            , fetchUsers shared.token
            )
        Nothing ->
            ( Model Nothing shared.key Api.Data.NotAsked HideMode Api.Data.NotAsked "" "" "" Nothing
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
    | UpdateRole String
    | UpdatePreferredHours String
    | Modal ModalMode
    | ModalCreateResponse (Data UserWithToken)
    | ModalEditResponse (Data User)


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

        UpdateRole role ->
            ( { model | role = role}
            , Cmd.none
            )
        
        UpdatePreferredHours preferredHours ->
            ( { model | preferredHours = String.toInt preferredHours }
            , Cmd.none
            )

        ModalSubmit ->
            ( model
            , case model.modalMode of
                  NewMode ->
                      Api.User.create
                        { token = model.token
                        , user =
                            { username = model.username
                            , password = model.password
                            , role = Just model.role
                            , preferredHours = model.preferredHours
                            }
                        , onResponse = ModalCreateResponse 
                        }

                  EditMode user ->
                      Api.User.update
                        { token = model.token
                        , user =
                            { id = user.id
                            , username = Just model.username
                            , password = if model.password == "" then Nothing else Just model.password
                            , role = Just model.role
                            , preferredHours = model.preferredHours
                            }
                        , onResponse = ModalEditResponse 
                        }

                  HideMode -> Cmd.none
            )

        ModalCreateResponse data ->
            let
                response = case data of
                    Api.Data.Success userWithToken -> Api.Data.Success userWithToken.user
                    Api.Data.Failure err -> Api.Data.Failure err
                    Api.Data.Loading -> Api.Data.Loading
                    Api.Data.NotAsked -> Api.Data.NotAsked

            in
            ( { model | modalResponse = response }
            , case Api.Data.toMaybe data of
                Just _ -> Nav.pushUrl model.key (Route.toString Route.Users)
                Nothing -> Cmd.none
            )

        ModalEditResponse data ->
            ( { model | modalResponse = data }
            , case Api.Data.toMaybe data of
                Just _ -> Nav.pushUrl model.key (Route.toString Route.Users)
                Nothing -> Cmd.none
            )

        Modal mode ->
            (
                case mode of
                    NewMode ->
                        { model
                        | modalMode = mode
                        , username = ""
                        , password = ""
                        , role = "user"
                        , preferredHours = Nothing
                        }
                    EditMode user ->
                        { model
                        | modalMode = mode
                        , username = user.username
                        , password = ""
                        , role = user.role
                        , preferredHours = user.preferredHours
                        }
                    HideMode ->
                        { model | modalMode = HideMode }

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
        , button [ class "inline", onClick (Modal NewMode) ] [ text "+ Add User" ]
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
      [ button [ class "inline", onClick ( Modal ( EditMode user ) ) ] [ text "Edit" ]
      , text " ??? "
      , button [ class "inline", onClick (DeleteUser user) ] [ text "Delete" ]
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

      isNew =
         case model.modalMode of
             NewMode -> True
             _ -> False
  in
  div [ class "modal", style "display" modalDisplay ]
      [ button [ class "modal-close", onClick (Modal HideMode) ] [ text "??" ]
      , h2 [] [ text modalHeader ]
      , Html.form [ onSubmit ModalSubmit ]
        [ viewInput "text" "Username" model.username True UpdateUsername
        , viewInput "password" "Password" model.password isNew UpdatePassword
        , select [ name "role", onInput UpdateRole]
            [ option [ value "user", selected (model.role == "user") ] [ text "User" ]
            , option [ value "manager", selected (model.role == "manager") ] [ text "Manager" ]
            , option [ value "admin", selected (model.role == "admin") ] [ text "Admin" ]
            ]
        , input
            [ type_ "number"
            , placeholder "Preferred Hours"
            , value ( String.fromInt ( Maybe.withDefault 1 model.preferredHours ) )
            , onInput UpdatePreferredHours
            , Html.Attributes.min "1"
            , Html.Attributes.max "24"
            ]
            []
        , viewValidation model
        ]
      ]

viewInput : String -> String -> String -> Bool -> (String -> msg) -> Html msg
viewInput t p v req toMsg =
  input [ type_ t, required req, placeholder p, value v, onInput toMsg ] []

viewValidation : Model -> Html msg
viewValidation model =
    let 
        isUsernameLength =
            (String.length model.username) >= 5

        isPasswordLength =
            (String.length model.password) >= 8 || (model.password == "")

        isDisabled =
             not (isUsernameLength && isPasswordLength)

        errorText =
            if not isUsernameLength then
                "Username too short"
            else if not isPasswordLength then
                "Password too short"
            else
                case model.modalResponse of
                    Api.Data.Failure list ->
                        Maybe.withDefault "" (List.head list)
                    _ ->
                        ""
    in
    div []
        [ div [ class "error" ] [ text errorText ]
        , button [type_ "submit", class "centered", disabled isDisabled ] [ text "Save" ]
        ]
