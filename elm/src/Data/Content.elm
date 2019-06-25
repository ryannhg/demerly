module Data.Content exposing (Content(..), decoder)

import Data.Homepage exposing (Homepage)
import Data.ProfileDetail exposing (ProfileDetail)
import Data.ProjectDetail exposing (ProjectDetail)
import Data.Settings exposing (Settings)
import Json.Decode as D exposing (Decoder)


type Content
    = Homepage Settings Homepage
    | ProfileDetail Settings ProfileDetail
    | ProjectDetail Settings ProjectDetail
    | OnlySettings Settings


decoder : Decoder Content
decoder =
    -- Remember: the order matters!
    D.oneOf
        [ page ProfileDetail Data.ProfileDetail.decoder
        , page ProjectDetail Data.ProjectDetail.decoder
        , page Homepage Data.Homepage.decoder
        , D.map OnlySettings
            (D.field "settings" Data.Settings.decoder)
        ]


page : (Settings -> a -> b) -> Decoder a -> Decoder b
page ctr pageDecoder =
    D.map2 ctr
        (D.field "settings" Data.Settings.decoder)
        (D.field "page" pageDecoder)
