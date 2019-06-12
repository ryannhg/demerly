module Route exposing
    ( Route(..)
    , fromUrl
    , toUrl
    )

import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser)


type Route
    = ProfileDetail String
    | NotFound


router : Parser (Route -> a) a
router =
    Parser.oneOf
        [ Parser.map ProfileDetail (Parser.s "profile" </> Parser.string)
        ]


fromUrl : Url -> Route
fromUrl =
    Parser.parse router >> Maybe.withDefault NotFound


toUrl : Route -> Url -> Url
toUrl route url =
    { url
        | path =
            case route of
                ProfileDetail slug ->
                    "/profile/" ++ slug

                NotFound ->
                    "/not-found"
    }
