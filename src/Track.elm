module Track exposing (..)

import Json.Decode as JD exposing (Decoder)

type alias TrackDistanceRequest =
    { id : String
    , position : Float
    }


type alias TrackPoint =
    { x : Float
    , y : Float
    }

trackPointDecoder : Decoder TrackPoint
trackPointDecoder =
  JD.map2 TrackPoint
    (JD.field "x" JD.float)
    (JD.field "y" JD.float)
