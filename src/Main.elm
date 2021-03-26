module Main exposing (main)

import Browser
import Html exposing (Html, div, h1, span, text)
import Json.Decode as JD
import Ports exposing (getPointAtTrackDistance, gotPointAtTrackDistance, gotTrackLength, requestTrackLength)
import Svg
import Svg.Attributes as Satt
import Time
import Track exposing (TrackDistanceRequest, TrackPoint, trackPointDecoder)


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
            ( { model | trackLength = Just a }, Cmd.none )

        GotTrackPoint a ->
            ( { model | trackCoordinates = Just a }, Cmd.none )

        Noop ->
            ( model, Cmd.none )

        Tick _ ->
            case model.trackLength of
                Nothing ->
                    ( model, Cmd.none )

                Just length ->
                    if model.trackPosition > length then
                        ( { model | trackPosition = 0 }, getPointAtTrackDistance { id = "track", position = model.trackPosition } )

                    else
                        ( { model | trackPosition = model.trackPosition + 0.5 }, getPointAtTrackDistance { id = "track", position = model.trackPosition } )


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { trackLength = Nothing, trackPosition = 0, trackCoordinates = Nothing }, requestTrackLength "track" )


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
            [ Satt.width "230"
            , Satt.height "230"
            , Satt.viewBox "0 0 130 130"
            ]
            [ Svg.path
                [ Satt.d "M 32 56 A 8 8 90 0 0 32 72 C 40 72 48 48 48 56 L 48 72 C 48 80 48 88 64 80 C 64 80 80 72 72 88 C 64 96 72 96 64 104 A 11.36 11.36 90 0 1 48 104 A 40 40 90 0 0 32 80 Q 28 79.2 28 84 T 16 94.4 T 9.6 88 T 20 76 T 24 72 A 40 40 90 0 0 8 56 A 11.36 11.36 90 0 1 0 48 C 8 40 24 40 24 48 C 32 48 40 56 32 56"
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
        , div [] [ text ("Track position " ++ String.fromFloat model.trackPosition) ]
        ]


mapTrackPoint : JD.Value -> Msg
mapTrackPoint jsonValue =
    case JD.decodeValue trackPointDecoder jsonValue of
        Ok trackpoint ->
            GotTrackPoint trackpoint

        Err _ ->
            Noop


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ gotTrackLength GotTrackLength
        , gotPointAtTrackDistance mapTrackPoint
        , Time.every 25 Tick
        ]
