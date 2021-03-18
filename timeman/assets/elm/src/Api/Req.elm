module Api.Req exposing
    ( Token(..)
    , tokenDecoder, encodeToken
    , get, put, patch, post, delete
    )

{-|

@docs Token
@docs decoder, encode
@docs get, put, post, delete

-}

import Http
import Json.Decode as Json
import Json.Encode as Encode


type Token
    = Token String


tokenDecoder : Json.Decoder Token
tokenDecoder =
    Json.map Token Json.string


encodeToken : Token -> Json.Value
encodeToken (Token token) =
    Encode.string token



-- HTTP HELPERS


get :
    Maybe Token
    ->
        { url : String
        , expect : Http.Expect msg
        }
    -> Cmd msg
get =
    request "GET" Http.emptyBody


delete :
    Maybe Token
    ->
        { url : String
        , expect : Http.Expect msg
        }
    -> Cmd msg
delete =
    request "DELETE" Http.emptyBody


post :
    Maybe Token
    ->
        { url : String
        , body : Http.Body
        , expect : Http.Expect msg
        }
    -> Cmd msg
post token options =
    request "POST" options.body token options


put :
    Maybe Token
    ->
        { url : String
        , body : Http.Body
        , expect : Http.Expect msg
        }
    -> Cmd msg
put token options =
    request "PUT" options.body token options

patch :
    Maybe Token
    ->
        { url : String
        , body : Http.Body
        , expect : Http.Expect msg
        }
    -> Cmd msg
patch token options =
    request "PATCH" options.body token options


request :
    String
    -> Http.Body
    -> Maybe Token
    ->
        { options
            | url : String
            , expect : Http.Expect msg
        }
    -> Cmd msg
request method body maybeToken options =
    Http.request
        { method = method
        , headers =
            case maybeToken of
                Just (Token token) ->
                    [ Http.header "Authorization" ("Bearer " ++ token) ]

                Nothing ->
                    []
        , url = options.url
        , body = body
        , expect = options.expect
        , timeout = Just (1000 * 60) -- 60 second timeout
        , tracker = Nothing
        }

