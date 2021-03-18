module Spa.Generated.Pages exposing
    ( Model
    , Msg
    , init
    , load
    , save
    , subscriptions
    , update
    , view
    )

import Pages.Top
import Pages.NotFound
import Pages.Register
import Pages.Settings
import Pages.SignIn
import Shared
import Spa.Document as Document exposing (Document)
import Spa.Generated.Route as Route exposing (Route)
import Spa.Page exposing (Page)
import Spa.Url as Url


-- TYPES


type Model
    = Top__Model Pages.Top.Model
    | NotFound__Model Pages.NotFound.Model
    | Register__Model Pages.Register.Model
    | Settings__Model Pages.Settings.Model
    | SignIn__Model Pages.SignIn.Model


type Msg
    = Top__Msg Pages.Top.Msg
    | NotFound__Msg Pages.NotFound.Msg
    | Register__Msg Pages.Register.Msg
    | Settings__Msg Pages.Settings.Msg
    | SignIn__Msg Pages.SignIn.Msg



-- INIT


init : Route -> Shared.Model -> ( Model, Cmd Msg )
init route =
    case route of
        Route.Top ->
            pages.top.init ()
        
        Route.NotFound ->
            pages.notFound.init ()
        
        Route.Register ->
            pages.register.init ()
        
        Route.Settings ->
            pages.settings.init ()
        
        Route.SignIn ->
            pages.signIn.init ()



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update bigMsg bigModel =
    case ( bigMsg, bigModel ) of
        ( Top__Msg msg, Top__Model model ) ->
            pages.top.update msg model
        
        ( NotFound__Msg msg, NotFound__Model model ) ->
            pages.notFound.update msg model
        
        ( Register__Msg msg, Register__Model model ) ->
            pages.register.update msg model
        
        ( Settings__Msg msg, Settings__Model model ) ->
            pages.settings.update msg model
        
        ( SignIn__Msg msg, SignIn__Model model ) ->
            pages.signIn.update msg model
        
        _ ->
            ( bigModel, Cmd.none )



-- BUNDLE - (view + subscriptions)


bundle : Model -> Bundle
bundle bigModel =
    case bigModel of
        Top__Model model ->
            pages.top.bundle model
        
        NotFound__Model model ->
            pages.notFound.bundle model
        
        Register__Model model ->
            pages.register.bundle model
        
        Settings__Model model ->
            pages.settings.bundle model
        
        SignIn__Model model ->
            pages.signIn.bundle model


view : Model -> Document Msg
view model =
    (bundle model).view ()


subscriptions : Model -> Sub Msg
subscriptions model =
    (bundle model).subscriptions ()


save : Model -> Shared.Model -> Shared.Model
save model =
    (bundle model).save ()


load : Model -> Shared.Model -> ( Model, Cmd Msg )
load model =
    (bundle model).load ()



-- UPGRADING PAGES


type alias Upgraded params model msg =
    { init : params -> Shared.Model -> ( Model, Cmd Msg )
    , update : msg -> model -> ( Model, Cmd Msg )
    , bundle : model -> Bundle
    }


type alias Bundle =
    { view : () -> Document Msg
    , subscriptions : () -> Sub Msg
    , save : () -> Shared.Model -> Shared.Model
    , load : () -> Shared.Model -> ( Model, Cmd Msg )
    }


upgrade : (model -> Model) -> (msg -> Msg) -> Page params model msg -> Upgraded params model msg
upgrade toModel toMsg page =
    let
        init_ params shared =
            page.init shared (Url.create params shared.key shared.url) |> Tuple.mapBoth toModel (Cmd.map toMsg)

        update_ msg model =
            page.update msg model |> Tuple.mapBoth toModel (Cmd.map toMsg)

        bundle_ model =
            { view = \_ -> page.view model |> Document.map toMsg
            , subscriptions = \_ -> page.subscriptions model |> Sub.map toMsg
            , save = \_ -> page.save model
            , load = \_ -> load_ model
            }

        load_ model shared =
            page.load shared model |> Tuple.mapBoth toModel (Cmd.map toMsg)
    in
    { init = init_
    , update = update_
    , bundle = bundle_
    }


pages :
    { top : Upgraded Pages.Top.Params Pages.Top.Model Pages.Top.Msg
    , notFound : Upgraded Pages.NotFound.Params Pages.NotFound.Model Pages.NotFound.Msg
    , register : Upgraded Pages.Register.Params Pages.Register.Model Pages.Register.Msg
    , settings : Upgraded Pages.Settings.Params Pages.Settings.Model Pages.Settings.Msg
    , signIn : Upgraded Pages.SignIn.Params Pages.SignIn.Model Pages.SignIn.Msg
    }
pages =
    { top = Pages.Top.page |> upgrade Top__Model Top__Msg
    , notFound = Pages.NotFound.page |> upgrade NotFound__Model NotFound__Msg
    , register = Pages.Register.page |> upgrade Register__Model Register__Msg
    , settings = Pages.Settings.page |> upgrade Settings__Model Settings__Msg
    , signIn = Pages.SignIn.page |> upgrade SignIn__Model SignIn__Msg
    }