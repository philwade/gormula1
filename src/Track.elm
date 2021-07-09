module Track exposing (..)

import Json.Decode as JD exposing (Decoder)


type alias TrackDistanceRequest =
    { id : String
    , position : Float
    , driverId : String
    }


type alias TrackPoint =
    { x : Float
    , y : Float
    }


type alias DriverTrackPoint =
    { x : Float
    , y : Float
    , driverId : String
    , position : Float
    }


driverTrackPointDecoder : Decoder DriverTrackPoint
driverTrackPointDecoder =
    JD.map4 DriverTrackPoint
        (JD.field "x" JD.float)
        (JD.field "y" JD.float)
        (JD.field "driverId" JD.string)
        (JD.field "position" JD.float)


trackPointDecoder : Decoder TrackPoint
trackPointDecoder =
    JD.map2 TrackPoint
        (JD.field "x" JD.float)
        (JD.field "y" JD.float)
