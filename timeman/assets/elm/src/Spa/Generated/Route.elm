module Spa.Generated.Route exposing
    ( Route(..)
    , fromUrl
    , toString
    )

import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser)


type Route
    = Top
    | NotFound
    | Register
    | Settings
    | SignIn
    | Users


fromUrl : Url -> Maybe Route
fromUrl =
    Parser.parse routes


routes : Parser (Route -> a) a
routes =
    Parser.oneOf
        [ Parser.map Top Parser.top
        , Parser.map NotFound (Parser.s "not-found")
        , Parser.map Register (Parser.s "register")
        , Parser.map Settings (Parser.s "settings")
        , Parser.map SignIn (Parser.s "sign-in")
        , Parser.map Users (Parser.s "users")
        ]


toString : Route -> String
toString route =
    let
        segments : List String
        segments =
            case route of
                Top ->
                    []
                
                NotFound ->
                    [ "not-found" ]
                
                Register ->
                    [ "register" ]
                
                Settings ->
                    [ "settings" ]
                
                SignIn ->
                    [ "sign-in" ]
                
                Users ->
                    [ "users" ]
    in
    segments
        |> String.join "/"
        |> String.append "/"