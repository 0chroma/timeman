module Api.Routes exposing (Endpoint(..), route)


type Endpoint
    = Users
    | Entries
    | User (Int)
    | Entry (Int)
    | SignIn

route : Endpoint -> String
route endpoint = 
    case endpoint of
        Users ->
            "/api/users"
        Entries ->
            "/api/entries"
        User id ->
            "/api/users/" ++ String.fromInt id
        Entry id ->
            "/api/entries/" ++ String.fromInt id
        SignIn ->
            "/api/users/signin"

