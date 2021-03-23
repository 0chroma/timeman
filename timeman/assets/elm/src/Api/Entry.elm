module Api.Entry exposing
    ( Entry
    , decoder, encode
    , create, update, delete, list
    )

{-|

@docs Entry
@docs decoder, encode

@docs authentication, registration, current, update

-}

import Api.Data exposing (Data)
import Api.Req exposing (Token)
import Api.Routes exposing (Endpoint, route)
import Api.User
import Http
import Dict exposing (Dict)
import Json.Decode as Json
import Json.Encode as Encode
import Utils.Json


type alias Entry =
    { id : Int
    , date : String
    , hours : Int
    , notes : String
    , user : Api.User.User
    }


-- Json

decoder : Json.Decoder Entry
decoder =
    Json.map5 Entry
        (Json.field "id" Json.int)
        (Json.field "date" Json.string)
        (Json.field "hours" Json.int)
        (Json.field "notes" Json.string)
        (Json.field "user" Api.User.decoder)



encode : Entry -> Json.Value
encode entry =
    Encode.object
        [ ( "date", Encode.string entry.date )
        , ( "hours", Encode.int entry.hours )
        , ( "notes", Encode.string entry.notes )
        , ( "user", Api.User.encode entry.user )
        ]



-- Requests

create :
    { token : Maybe Token
    , entry :
        { entry
            | date : String
            , hours : Int
            , notes : String
            , user_id : Int
        }
    , onResponse : Data Entry -> msg
    }
    -> Cmd msg
create options =
    let
        body : Json.Value
        body =
            Encode.object
                [ ( "entry"
                  , Encode.object
                        [ ( "date", Encode.string options.entry.date)
                        , ( "hours", Encode.int options.entry.hours )
                        , ( "notes", Encode.string options.entry.notes )
                        , ( "user_id", Encode.int options.entry.user_id )
                        ]
                  )
                ]
    in
    Api.Req.post (options.token)
        { url = route Api.Routes.Entries
        , body = Http.jsonBody body
        , expect =
            Api.Data.expectJson options.onResponse decoder
        }


update :
    { token : Maybe Token
    , entry :
        { entry
            | id : Int
            , date : Maybe String
            , hours : Maybe Int
            , notes : Maybe String
            , user_id : Maybe Int
        }
    , onResponse : Data Entry -> msg
    }
    -> Cmd msg
update options =
    let
        body : Json.Value
        body =
            Encode.object
                [ ( "entry"
                  , Encode.object
                        (List.concat
                            [ case options.entry.date of
                                Just date ->
                                    [ ( "date", Encode.string date ) ]
                                Nothing ->
                                    []
                            , case options.entry.hours of
                                Just hours ->
                                    [ ( "hours", Encode.int hours ) ]
                                Nothing ->
                                    []
                            , case options.entry.notes of
                                Just notes ->
                                    [ ( "notes", Encode.string notes ) ]
                                Nothing ->
                                    []
                            , case options.entry.user_id of
                                Just user_id ->
                                    [ ( "user_id", Encode.int user_id ) ]
                                Nothing ->
                                    []
                            ]
                        )
                  )
                ]
    in
    Api.Req.patch (options.token)
        { url = route (Api.Routes.Entry options.entry.id)
        , body = Http.jsonBody body
        , expect =
            Api.Data.expectJson options.onResponse decoder
        }

filter_to_query : String -> Maybe String -> String
filter_to_query name value =
    Maybe.withDefault "" ( Maybe.map ( \val -> name ++ "=" ++ val) value )

list :
    { token : Maybe Token
    , onResponse : Data (List Entry) -> msg
    , filters : 
      { filters
      | start_date : Maybe String
      , end_date : Maybe String
      }
    }
    -> Cmd msg
list options =
    let 
        query =
            [ ( filter_to_query "start_date" options.filters.start_date )
            , ( filter_to_query "end_date" options.filters.end_date )
            ]
            |> List.filter ( \item -> not ( item == "" ) )
            |> String.join "&"
        url = ( route (Api.Routes.Entries) ) ++ "?" ++ query
    in
    Api.Req.get (options.token)
        { url = url 
        , expect =
            Api.Data.expectJson options.onResponse (Json.list decoder)
        }

delete :
    { token : Maybe Token
    , entry :
        { entry
            | id : Int
        }
    , onResponse : Data () -> msg
    }
    -> Cmd msg
delete options =
    Api.Req.delete (options.token)
        { url = route (Api.Routes.Entry options.entry.id)
        , expect =
            Api.Data.expectStatus options.onResponse
        }
