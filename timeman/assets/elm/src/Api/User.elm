module Api.User exposing
    ( User
    , decoder, encode
    , authentication, registration, update
    )

{-|

@docs User
@docs decoder, encode

@docs authentication, registration, current, update

-}

import Api.Data exposing (Data)
import Api.Req exposing (Token)
import Api.Routes exposing (Endpoint, route)
import Http
import Json.Decode as Json
import Json.Encode as Encode
import Utils.Json


type alias User =
    { username : String
    , token : Token 
    , role : String
    , id : Int
    , preferredHours : Maybe Int
    }


decoder : Json.Decoder User
decoder =
    Json.map5 User
        (Json.field "username" Json.string)
        (Json.field "token" Api.Req.tokenDecoder)
        (Json.field "role" Json.string)
        (Json.field "id" Json.int)
        (Json.field "preferredHours" (Json.maybe Json.int))


encode : User -> Json.Value
encode user =
    Encode.object
        [ ( "username", Encode.string user.username )
        , ( "token", Api.Req.encodeToken user.token )
        , ( "role", Encode.string user.role )
        , ( "id", Encode.int user.id )
        , ( "preferredHours", Utils.Json.maybe Encode.int user.preferredHours )
        ]


authentication :
    { user : { user | username: String, password : String }
    , onResponse : Data User -> msg
    }
    -> Cmd msg
authentication options =
    let
        body : Json.Value
        body =
            Encode.object
                [ ( "username", Encode.string options.user.username )
                , ( "password", Encode.string options.user.password )
                ]
    in
    Http.post
        { url = route Api.Routes.SignIn
        , body = Http.jsonBody body
        , expect =
            Api.Data.expectJson options.onResponse decoder
        }


registration :
    { user :
        { user
            | username : String
            , password : String
            , role : Maybe String
        }
    , onResponse : Data User -> msg
    }
    -> Cmd msg
registration options =
    let
        body : Json.Value
        body =
            Encode.object
                [ ( "user"
                  , Encode.object
                        [ ( "username", Encode.string options.user.username )
                        , ( "password", Encode.string options.user.password )
                        , ( "role", Encode.string (Maybe.withDefault "user" options.user.role ) )
                        ]
                  )
                ]
    in
    Http.post
        { url = route Api.Routes.Users
        , body = Http.jsonBody body
        , expect =
            Api.Data.expectJson options.onResponse decoder
        }


update :
    { token : Token
    , user :
        { user
            | username : String
            , password : Maybe String
            , role : String
            , id : Int
            , preferredHours : Maybe Int
        }
    , onResponse : Data User -> msg
    }
    -> Cmd msg
update options =
    let
        body : Json.Value
        body =
            Encode.object
                [ ( "user"
                  , Encode.object
                        (List.concat
                            [ [ ( "username", Encode.string options.user.username )
                              , ( "role", Encode.string options.user.role )
                              ]
                            , case options.user.preferredHours of
                                Just preferredHours ->
                                    [ ( "preferredHours", Encode.int preferredHours ) ]

                                Nothing ->
                                    []
                            , case options.user.password of
                                Just password ->
                                    [ ( "password", Encode.string password ) ]

                                Nothing ->
                                    []
                            ]
                        )
                  )
                ]
    in
    Api.Req.put (Just options.token)
        { url = route (Api.Routes.User options.user.id)
        , body = Http.jsonBody body
        , expect =
            Api.Data.expectJson options.onResponse decoder
        }

