module Pages.Top exposing (Params, Model, Msg, page)

import Api.Data exposing (Data)
import Api.Entry exposing (Entry)
import Api.User exposing (User)
import Api.Req exposing (Token)
import Browser.Navigation as Nav exposing (Key)
import Export
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
    , filterStartDate : String
    , filterEndDate : String
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
                ""
                ""
            , fetchEntries shared.token "" ""
            )
        Nothing ->
            ( Model Nothing shared.key Api.User.empty Api.Data.NotAsked NewMode "" 0 "" "" ""
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
    | UpdateFilterStart String
    | UpdateFilterEnd String
    | ExportData


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
          , fetchEntries model.token model.filterStartDate model.filterEndDate
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

        UpdateFilterStart date ->
            ( { model | filterStartDate = date}
            , fetchEntries model.token date model.filterEndDate
            )

        UpdateFilterEnd date ->
            ( { model | filterEndDate = date}
            , fetchEntries model.token model.filterStartDate date
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
                            , user_id = Just entry.user.id
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

        ExportData ->
            case Api.Data.toMaybe model.entries of
              Just entries_ -> 
                  ( model, Export.entries entries_ )
              Nothing ->
                  ( model, Cmd.none )



save : Model -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

fetchEntries : Maybe Api.Req.Token -> String -> String -> Cmd Msg
fetchEntries token startDate endDate =
    let
        dates = case (startDate, endDate) of
            ("", "") ->
                { start_date = Nothing
                , end_date = Nothing
                }
            (start, "") ->
                { start_date = Just start
                , end_date = Nothing
                }
            ("", end) ->
                { start_date = Nothing
                , end_date = Just end
                }
            (start, end) ->
                { start_date = Just start
                , end_date = Just end
                }
    in
    Api.Entry.list
        { token = token
        , onResponse = GotEntries
        , filters = dates
        }


-- VIEW


view : Model -> Document Msg
view model =
    { title = "Log Entries"
    , body = case Api.Data.toMaybe model.entries of
      Just entries_ -> 
        [ h2 [] [ text "Log Entries" ]
        , button [ class "inline", onClick (Modal NewMode) ] [ text "+ Add Log Entry" ]
        , entryFilters model
        , button [ class "inline", onClick ExportData ] [ text "Export" ]
        , entryTable entries_
        , entryModal model
        ]
      Nothing ->
        [ h2 [] [ text "Loading..." ] ]
    }

entryTable : List Entry -> Html Msg
entryTable entries =
    table [ class "big-table" ]
    ( List.concat
      [ [ tr []
          [ th [] [ text "Date" ]
          , th [] [ text "Hours" ]
          , th [] [ text "Notes" ]
          , th [] [ text "User" ]
          , th [] [ text "Action" ]
          ]
        ]
      , (List.map entryRow entries)
      ]
    )

entryRow : Entry -> Html Msg
entryRow entry =
    let
        isFlagged = case entry.user.preferredHours of
            Just hours ->
               hours > entry.hours 
            Nothing -> False
    in
    tr [ class ( if isFlagged then "flagged" else "ok" ) ]
    [ td [] [ text entry.date ]
    , td [] [ text ( String.fromInt entry.hours ) ]
    , td [] ( String.split "\n" entry.notes |> List.map ( \line -> div [] [ text line ] ) )
    , td [] [ text entry.user.username ]
    , td []
      [ button [ class "inline", onClick ( Modal ( EditMode entry ) ) ] [ text "Edit" ]
      , text " ??? "
      , button [ class "inline", onClick (DeleteEntry entry) ] [ text "Delete" ]
      ]
    ]

entryFilters : Model -> Html Msg
entryFilters model =
  span [ class "filters" ]
      [ text "Filter: "
      , viewInput "date" "Start Date" model.filterStartDate UpdateFilterStart
      , text " "
      , button [ class "inline reset", onClick ( UpdateFilterStart "" ) ] [ text "x" ]
      , text " to "
      , viewInput "date" "End Date" model.filterEndDate UpdateFilterEnd
      , text " "
      , button [ class "inline reset", onClick ( UpdateFilterEnd "" ) ] [ text "x" ]
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
      [ button [ class "modal-close", onClick (Modal HideMode) ] [ text "??" ]
      , h2 [] [ text modalHeader ]
      , Html.form [ onSubmit ModalSubmit ]
        [ viewInput "date" "Date" model.entryDate UpdateDate
        , input
            [ type_ "number"
            , placeholder "Hours"
            , value ( String.fromInt model.entryHours )
            , onInput UpdateHours
            , Html.Attributes.min "1"
            , Html.Attributes.max "24"
            ]
            []
        , textarea [ required True, onInput UpdateNotes ] [ text model.entryNotes ]
        , button [ type_ "submit" ] [ text "Save" ]
        ]
      ]

viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  input [ type_ t, required True, placeholder p, value v, onInput toMsg ] []
