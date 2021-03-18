port module Ports exposing (clearUser, saveUser)

import Api.User exposing (UserWithToken)
import Json.Decode as Json
import Json.Encode as Encode


port outgoing :
    { tag : String
    , data : Json.Value
    }
    -> Cmd msg


saveUser : UserWithToken -> Cmd msg
saveUser user =
    outgoing
        { tag = "saveUser"
        , data = Api.User.encodeWithToken user
        }


clearUser : Cmd msg
clearUser =
    outgoing
        { tag = "clearUser"
        , data = Encode.null
        }
