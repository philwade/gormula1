module Main exposing (main)

import Browser
import Html exposing (Html, div, h1, span, text)
import Ports exposing (getPointAtTrackDistance, gotPointAtTrackDistance, gotTrackLength, requestTrackLength)
import Track exposing (TrackDistanceRequest, TrackPoint, trackPointDecoder)
import Svg
import Svg.Attributes as Satt
import Json.Decode as JD
import Time


main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { trackLength : Maybe Float
    , trackCoordinates : Maybe TrackPoint
    , trackPosition : Float
    }


type Msg
    = GotTrackLength Float
    | GotTrackPoint TrackPoint
    | Noop
    | Tick Time.Posix


type alias Flags =
    Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTrackLength a ->
            ( { model | trackLength = Just a }, Cmd.none)

        GotTrackPoint a ->
            ( { model | trackCoordinates = Just a }, Cmd.none )
        Noop ->
          (model, Cmd.none)
        Tick _ ->
          case model.trackLength of
            Nothing ->
              (model, Cmd.none)
            Just length ->
              if model.trackPosition > length then
                ( { model | trackPosition = 0 }, getPointAtTrackDistance { id = "track", position = model.trackPosition })
              else
                ( { model | trackPosition = model.trackPosition + 1 }, getPointAtTrackDistance { id = "track", position = model.trackPosition })


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { trackLength = Nothing, trackPosition = 0, trackCoordinates = Nothing}, requestTrackLength "track" )


view : Model -> Html Msg
view model =
    let
        trackLength =
            case model.trackLength of
                Nothing ->
                    "none"

                Just a ->
                    String.fromFloat a
    in
    div []
        [ Svg.svg
            [ Satt.width "130"
            , Satt.height "130"
            , Satt.viewBox "0 0 130 130"
            ]
            [ Svg.circle
                [ Satt.cx "60"
                , Satt.cy "50"
                , Satt.r "50"
                , Satt.id "track"
                ]
                []
            , case model.trackCoordinates of
                Nothing ->
                    span [] []

                Just p ->
                    Svg.circle
                        [ Satt.cx <| String.fromFloat p.x
                        , Satt.cy <| String.fromFloat p.y
                        , Satt.r "3"
                        , Satt.class "spot"
                        ]
                        []
            ]
        , div [] [ text ("Track length " ++ trackLength) ]
        , div [] [ text ("Track position " ++ (String.fromFloat model.trackPosition)) ]
        ]

mapTrackPoint : JD.Value -> Msg
mapTrackPoint jsonValue =
  case (JD.decodeValue trackPointDecoder jsonValue) of
    Ok trackpoint -> GotTrackPoint trackpoint
    Err _ ->
            Noop



subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ gotTrackLength GotTrackLength
        , gotPointAtTrackDistance mapTrackPoint
        , Time.every 1000 Tick
        ]
