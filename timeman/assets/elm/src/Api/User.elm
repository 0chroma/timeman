module Api.User exposing
    ( User, UserWithToken
    , decoder, encode, userWithTokenDecoder, encodeWithToken
    , authentication, create, update, delete, list
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
    , role : String
    , id : Int
    , preferredHours : Maybe Int
    }

type alias UserWithToken =
    { user : User
    , token : Api.Req.Token
    }


-- Json

decoder : Json.Decoder User
decoder =
    Json.map4 User
        (Json.field "username" Json.string)
        (Json.field "role" Json.string)
        (Json.field "id" Json.int)
        (Json.field "preferredHours" (Json.maybe Json.int))

userWithTokenDecoder : Json.Decoder UserWithToken
userWithTokenDecoder =
    Json.map2 UserWithToken
        decoder
        (Json.field "token" (Api.Req.tokenDecoder))

encodeFields : User -> List ( String, Encode.Value )
encodeFields user = 
    [ ( "username", Encode.string user.username )
    , ( "role", Encode.string user.role )
    , ( "id", Encode.int user.id )
    , ( "preferredHours", Utils.Json.maybe Encode.int user.preferredHours )
    ]


encode : User -> Json.Value
encode user =
    Encode.object (encodeFields user)

encodeWithToken : UserWithToken -> Json.Value
encodeWithToken userToken =
    Encode.object (List.concat
        [ (encodeFields userToken.user)
        , [ ( "token", Api.Req.encodeToken userToken.token ) ]
        ]
    )




-- Requests

authentication :
    { user : { user | username: String, password : String }
    , onResponse : Data UserWithToken -> msg
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
            Api.Data.expectJson options.onResponse userWithTokenDecoder
        }


signup :
    { user :
        { user
            | username : String
            , password : String
            , role : Maybe String
        }
    , onResponse : Data UserWithToken -> msg
    }
    -> Cmd msg
signup options =
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
        { url = route Api.Routes.SignUp
        , body = Http.jsonBody body
        , expect =
            Api.Data.expectJson options.onResponse userWithTokenDecoder
        }

create :
    { token : Maybe Token
    , user :
        { user
            | username : String
            , password : String
            , role : Maybe String
        }
    , onResponse : Data UserWithToken -> msg
    }
    -> Cmd msg
create options =
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
    Api.Req.post (options.token)
        { url = route Api.Routes.Users
        , body = Http.jsonBody body
        , expect =
            Api.Data.expectJson options.onResponse userWithTokenDecoder
        }


update :
    { token : Maybe Token
    , user :
        { user
            | username : Maybe String
            , password : Maybe String
            , role : Maybe String
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
                            [ case options.user.username of
                                Just username ->
                                    [ ( "username", Encode.string username ) ]

                                Nothing ->
                                    []
                            , case options.user.role of
                                Just role ->
                                    [ ( "role", Encode.string role ) ]

                                Nothing ->
                                    []
                            , case options.user.preferredHours of
                                Just preferredHours ->
                                    [ ( "preferred_hours", Encode.int preferredHours ) ]

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
    Api.Req.patch (options.token)
        { url = route (Api.Routes.User options.user.id)
        , body = Http.jsonBody body
        , expect =
            Api.Data.expectJson options.onResponse decoder
        }


list :
    { token : Maybe Token
    , onResponse : Data (List User) -> msg
    }
    -> Cmd msg
list options =
    Api.Req.get (options.token)
        { url = route (Api.Routes.Users)
        , expect =
            Api.Data.expectJson options.onResponse (Json.list decoder)
        }

delete :
    { token : Maybe Token
    , user :
        { user
            | id : Int
        }
    , onResponse : Data () -> msg
    }
    -> Cmd msg
delete options =
    Api.Req.delete (options.token)
        { url = route (Api.Routes.User options.user.id)
        , expect =
            Api.Data.expectStatus options.onResponse
        }
