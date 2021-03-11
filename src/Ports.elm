port module Ports exposing (..)

import Json.Encode exposing (Value)
import Track exposing (..)



port requestTrackLength : String -> Cmd msg


port gotTrackLength : (Float -> msg) -> Sub msg


port getPointAtTrackDistance : TrackDistanceRequest -> Cmd msg


port gotPointAtTrackDistance : (Value -> msg) -> Sub msg
