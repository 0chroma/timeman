module Export exposing (entries)

import File.Download as Download
import Html.String as Html exposing (..)
import Html.String.Attributes as Attr exposing (..)
import Api.Entry exposing (Entry)


entries : List Entry -> Cmd msg
entries list =
    let
        entryTable = 
          table [ class "big-table" ]
          ( List.concat
            [ [ tr []
                [ th [] [ text "Date" ]
                , th [] [ text "Hours" ]
                , th [] [ text "Notes" ]
                , th [] [ text "User" ]
                ]
              ]
            , (List.map entryRow list)
            ]
          )
    in
    Download.string "entries.html" "text/html" (Html.toString 2 entryTable)

entryRow : Entry -> Html msg
entryRow entry =
    let
        isFlagged = case entry.user.preferredHours of
            Just hours ->
               hours > entry.hours 
            Nothing -> False
    in
    tr [ style "background-color" ( if isFlagged then "#fcb8bb" else "#bafcb8" ) ]
    [ td [] [ text entry.date ]
    , td [] [ text ( String.fromInt entry.hours ) ]
    , td [] ( String.split "\n" entry.notes |> List.map ( \line -> div [] [ text line ] ) )
    , td [] [ text entry.user.username ]
    ]
