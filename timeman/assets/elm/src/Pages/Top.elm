module Pages.Top exposing (Params, Model, Msg, page)

import Api.Data exposing (Data)
import Api.Entry exposing (Entry)
import Api.User exposing (User)
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
    = EditMode Entry
    | NewMode
    | HideMode

type alias Model =
    { token : Maybe Token
    , key : Key
    , user : User
    , entries : Data (List Entry)
    , modalMode : ModalMode
    , entryDate : String
    , entryHours : Int
    , entryNotes : String
    }



init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    case shared.user of
        Just user ->
            ( Model
                shared.token
                shared.key
                user
                Api.Data.Loading
                HideMode
                ""
                0
                ""
            , fetchEntries shared.token
            )
        Nothing ->
            ( Model Nothing shared.key Api.User.empty Api.Data.NotAsked NewMode "" 0 ""
            , Nav.pushUrl shared.key (Route.toString Route.SignIn)
            )

-- UPDATE


type Msg
    = GotEntries ( Data ( List Entry ) )
    | AfterDelete ( Data () )
    | DeleteEntry Entry
    | ModalSubmit
    | Modal ModalMode
    | ModalResponse (Data Entry)
    | UpdateDate String
    | UpdateHours String
    | UpdateNotes String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotEntries entries ->
            case Api.Data.toMaybe entries of
                Just entries_ ->
                    ( { model
                        | entries = entries
                      }
                    , Cmd.none
                    )
                Nothing ->
                    ( { model
                      | entries = entries
                      }
                    , Cmd.none
                    )

        AfterDelete _ ->
          ( model
          , fetchEntries model.token
          )

        DeleteEntry entry ->
            ( model
            , Api.Entry.delete
                { token = model.token
                , entry = { id = entry.id }
                , onResponse = AfterDelete 
                }
            )

        UpdateDate date ->
            ( { model | entryDate = date }
            , Cmd.none
            )

        UpdateNotes notes ->
            ( { model | entryNotes = notes}
            , Cmd.none
            )
        
        UpdateHours hours ->
            ( case String.toInt hours of
                  Just hours_ -> { model | entryHours = hours_ }
                  Nothing -> model
            , Cmd.none
            )

        ModalSubmit ->
            ( model
            , case model.modalMode of
                  NewMode ->
                      Api.Entry.create
                        { token = model.token
                        , entry =
                            { date = model.entryDate
                            , hours = model.entryHours
                            , notes = model.entryNotes
                            , user_id = model.user.id
                            }
                        , onResponse = ModalResponse 
                        }

                  EditMode entry ->
                      Api.Entry.update
                        { token = model.token
                        , entry =
                            { id = entry.id
                            , date = Just model.entryDate
                            , hours = Just model.entryHours
                            , notes = Just model.entryNotes
                            , user_id = Just entry.user_id
                            }
                        , onResponse = ModalResponse 
                        }

                  HideMode -> Cmd.none
            )

        ModalResponse data ->
            ( model, Nav.pushUrl model.key (Route.toString Route.Top) )

        Modal mode ->
            (
                case mode of
                    NewMode ->
                        { model
                        | modalMode = mode
                        , entryDate = ""
                        , entryHours = (Maybe.withDefault 1 model.user.preferredHours )
                        , entryNotes = ""
                        }
                    EditMode entry ->
                        { model
                        | modalMode = mode
                        , entryDate = entry.date
                        , entryHours = entry.hours
                        , entryNotes = entry.notes
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

fetchEntries : Maybe Api.Req.Token -> Cmd Msg
fetchEntries token =
    Api.Entry.list
        { token = token
        , onResponse = GotEntries
        }


-- VIEW


view : Model -> Document Msg
view model =
    { title = "Log Entries"
    , body = case Api.Data.toMaybe model.entries of
      Just entries_ -> 
        [ h2 [] [ text "Log Entries" ]
        , a [ href "#", onClick (Modal NewMode) ] [ text "+ Add Log Entry" ]
        , table [ class "big-table" ]
          ( List.concat
            [ [ tr []
                [ th [] [ text "Date" ]
                , th [] [ text "Hours" ]
                , th [] [ text "Notes" ]
                , th [] [ text "User" ]
                , th [] [ text "Action" ]
                ]
              ]
            , (List.map entryRow entries_)
            ]
          )
        , ( entryModal model )
        ]
      Nothing ->
        [ h2 [] [ text "Loading..." ] ]
    }

entryRow : Entry -> Html Msg
entryRow entry =
    tr []
    [ td [] [ text entry.date ]
    , td [] [ text ( String.fromInt entry.hours ) ]
    , td [] ( String.split "\n" entry.notes |> List.map ( \line -> div [] [ text line ] ) )
    , td [] [ text ( String.fromInt entry.user_id ) ]
    , td []
      [ a [ href "#", onClick ( Modal ( EditMode entry ) ) ] [ text "Edit" ]
      , text " • "
      , a [ href "#", onClick (DeleteEntry entry) ] [ text "Delete" ]
      ]
    ]

entryModal : Model -> Html Msg
entryModal model =
  let
      modalHeader =
         case model.modalMode of
             EditMode _ -> "Edit Log Entry"
             NewMode -> "New Log Entry"
             _ -> ""

      modalDisplay =
         case model.modalMode of
             HideMode -> "none"
             _ -> "block"
  in
  div [ class "modal", style "display" modalDisplay ]
      [ button [ class "modal-close", onClick (Modal HideMode) ] [ text "×" ]
      , h2 [] [ text modalHeader ]
      , Html.form [ onSubmit ModalSubmit ]
        [ viewInput "date" "Date" model.entryDate UpdateDate
        , input
            [ type_ "number"
            , placeholder "Hours"
            , value ( String.fromInt model.entryHours )
            , onInput UpdateHours
            , Html.Attributes.min "1"
            , Html.Attributes.max "24"] []
        , textarea [ required True, onInput UpdateNotes ] [ text model.entryNotes ]
        , button [ type_ "submit" ] [ text "Save" ]
        ]
      ]

viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  input [ type_ t, required True, placeholder p, value v, onInput toMsg ] []
