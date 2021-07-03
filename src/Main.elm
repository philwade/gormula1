module Main exposing (main)

import Browser
import Dict exposing (Dict)
import Html exposing (Html, div, h1, span, text)
import Json.Decode as JD
import Ports exposing (getPointAtTrackDistance, gotPointAtTrackDistance, gotTrackLength, requestTrackLength)
import Random
import Svg
import Svg.Attributes as Satt
import Time
import Track exposing (DriverTrackPoint, TrackDistanceRequest, TrackPoint, driverTrackPointDecoder)


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
    , drivers : Dict String Driver
    }


type alias DisplayClass =
    String


type alias Id =
    String


type alias Speed =
    Float


type Msg
    = GotTrackLength Float
    | GotTrackPoint Id TrackPoint
    | Noop
    | DriverTick Id Time.Posix
    | GetVariations Time.Posix
    | GotVariations (List Float)


type alias Flags =
    Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTrackLength a ->
            ( { model | trackLength = Just a }, Cmd.none )

        GotTrackPoint id a ->
            ( { model | drivers = Dict.update id (\d -> Maybe.map (\d_ -> { d_ | trackPoint = Just a }) d) model.drivers }, Cmd.none )

        Noop ->
            ( model, Cmd.none )

        DriverTick id _ ->
            case ( Dict.get id model.drivers, model.trackLength ) of
                ( Just driver, Just length ) ->
                    if driver.trackPosition > length then
                        let
                            newDrivers =
                                Dict.update id
                                    (\d ->
                                        Maybe.map (\d_ -> { d_ | trackPosition = 0 }) d
                                    )
                                    model.drivers
                        in
                        ( { model | drivers = newDrivers }, getPointAtTrackDistance { id = "track", driverId = id, position = driver.trackPosition } )

                    else
                        let
                            newDrivers =
                                Dict.update id
                                    (\d ->
                                        Maybe.map (\d_ -> { d_ | trackPosition = driver.trackPosition + 0.5 }) d
                                    )
                                    model.drivers
                        in
                        ( { model | drivers = newDrivers }, getPointAtTrackDistance { id = "track", driverId = id, position = driver.trackPosition } )

                ( _, _ ) ->
                    ( model, Cmd.none )

        GetVariations _ ->
            let
                generatorLength =
                    Dict.size model.drivers

                generator =
                    Random.list generatorLength (Random.float 0 3)
            in
            ( model, Random.generate GotVariations generator )

        GotVariations values ->
            let
                keys =
                    Dict.keys model.drivers

                pairs =
                    List.map2 Tuple.pair keys values

                newDrivers =
                    List.foldl
                        (\( id, variance ) acc ->
                            Dict.update id
                                (\d ->
                                    Maybe.map
                                        (\d_ ->
                                            { d_ | variation = variance }
                                        )
                                        d
                                )
                                acc
                        )
                        model.drivers
                        pairs
            in
            ( { model | drivers = newDrivers }, Cmd.none )


type alias Driver =
    { displayClass : DisplayClass
    , trackPoint : Maybe TrackPoint
    , trackPosition : Float
    , speed : Speed
    , variation : Float
    }


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { trackLength = Nothing
      , trackPosition = 0
      , trackCoordinates = Nothing
      , drivers =
            Dict.fromList
                [ ( "HAM", Driver "mercedes" Nothing 0 15 0 )
                , ( "VER", Driver "redbull" Nothing 0 14 0 )
                , ( "SAI", Driver "ferrari" Nothing 0 13 0 )
                , ( "NOR", Driver "mclaren" Nothing 0 12 0 )
                ]
      }
    , requestTrackLength "track"
    )


track2 =
    "M 400 900 Q 150 50 300 400 Q 350 700 350 400 Q 350 50 400 600 C 450 550 450 50 750 800 C 550 50 550 550 900 300 A 50 50 0 1 1 400 900 "


track1 =
    "M 32 56 A 8 8 90 0 0 32 72 C 40 72 48 48 48 56 L 48 72 C 48 80 48 88 64 80 C 64 80 80 72 72 88 C 64 96 72 96 64 104 A 11.36 11.36 90 0 1 48 104 A 40 40 90 0 0 32 80 Q 28 79.2 28 84 T 16 94.4 T 9.6 88 T 20 76 T 24 72 A 40 40 90 0 0 8 56 A 11.36 11.36 90 0 1 0 48 C 8 40 24 40 24 48 C 32 48 40 56 32 56"


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
            [ Satt.width "1200"
            , Satt.height "1200"
            , Satt.viewBox "0 0 1300 1300"
            ]
          <|
            let
                track =
                    [ Svg.path
                        [ Satt.d track2
                        , Satt.id "track"
                        ]
                        []
                    ]

                drivers =
                    Dict.foldl
                        (\k v acc ->
                            case v.trackPoint of
                                Just p ->
                                    Svg.circle
                                        [ Satt.cx <| String.fromFloat p.x
                                        , Satt.cy <| String.fromFloat p.y
                                        , Satt.r "5"
                                        , Satt.class v.displayClass
                                        ]
                                        []
                                        :: acc

                                Nothing ->
                                    text "" :: acc
                        )
                        []
                        model.drivers
            in
            track ++ drivers
        , div [] [ text ("Track length " ++ trackLength) ]
        , div [] [ text ("Track position " ++ String.fromFloat model.trackPosition) ]
        ]


mapTrackPoint : JD.Value -> Msg
mapTrackPoint jsonValue =
    case JD.decodeValue driverTrackPointDecoder jsonValue of
        Ok driverTrackPoint ->
            GotTrackPoint driverTrackPoint.driverId { x = driverTrackPoint.x, y = driverTrackPoint.y }

        Err _ ->
            Noop


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        base =
            [ gotTrackLength GotTrackLength
            , gotPointAtTrackDistance mapTrackPoint
            , Time.every 1000 GetVariations
            ]

        cars =
            Dict.foldl
                (\k v acc ->
                    Time.every (v.speed + v.variation) (\t -> DriverTick k t) :: acc
                )
                []
                model.drivers
    in
    Sub.batch <|
        base
            ++ cars
