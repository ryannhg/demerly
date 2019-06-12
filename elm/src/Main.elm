module Main exposing (main)

import Application.Context as Context
import Application.Document as Document exposing (Document)
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Components
import Data.Content as Content exposing (Content)
import Data.Settings as Settings exposing (Settings)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, classList, css)
import Json.Decode as D
import Json.Encode as Json
import Page.ProfileDetail
import Process
import Style
import Task
import Url exposing (Url)


type alias Model =
    { key : Nav.Key
    , url : Url
    , transition : Transition
    , context : Context.Model
    , page : Page
    }


type Transition
    = Hidden
    | PageChanging
    | PageReady


pageTransitionSpeed : Float
pageTransitionSpeed =
    300


isLayoutVisible : Transition -> Bool
isLayoutVisible t =
    t /= Hidden


isPageVisible : Transition -> Bool
isPageVisible t =
    t == PageReady


type Page
    = ProfileDetail Page.ProfileDetail.Content
    | NotFound
    | BadJson String


type Msg
    = ContextSentMsg Context.Msg
    | AppRequestedUrl UrlRequest
    | AppChangedUrl Url
    | PushUrl Url
    | SetTransition Transition


main : Program Json.Value Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view >> toUnstyled
        , subscriptions = always Sub.none
        , onUrlRequest = AppRequestedUrl
        , onUrlChange = AppChangedUrl
        }



-- INIT


init : Json.Value -> Url -> Nav.Key -> ( Model, Cmd Msg )
init json url key =
    ( initModel json url key
    , delay pageTransitionSpeed (SetTransition PageReady)
    )


initModel : Json.Value -> Url -> Nav.Key -> Model
initModel json url key =
    Model
        key
        url
        Hidden
        Context.init
        (case D.decodeValue Content.decoder json of
            Ok content ->
                initPage content

            Err reason ->
                BadJson (D.errorToString reason)
        )


initPage : Content -> Page
initPage content =
    case content of
        Content.ProfileDetail settings page ->
            ProfileDetail
                (Page.ProfileDetail.Content
                    page
                    settings
                )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ContextSentMsg msg_ ->
            ( { model | context = Context.update msg_ model.context }
            , Cmd.none
            )

        AppRequestedUrl request ->
            case request of
                Internal url ->
                    ( { model
                        | transition = PageChanging
                      }
                    , delay pageTransitionSpeed (PushUrl url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        PushUrl url ->
            ( model
            , Nav.pushUrl model.key (Url.toString url)
            )

        AppChangedUrl url ->
            ( { model
                | transition = PageReady
                , context = Context.hideMenu model.context
                , url = url
              }
            , Cmd.none
            )

        SetTransition transition ->
            ( { model | transition = transition }
            , Cmd.none
            )


delay : Float -> msg -> Cmd msg
delay ms msg =
    Process.sleep ms
        |> Task.perform (always msg)



-- VIEW


toUnstyled { title, body } =
    { title = title
    , body = List.map Html.Styled.toUnstyled body
    }


view : Model -> Document Msg
view model =
    let
        ( page, settings ) =
            viewPage model
    in
    { title = page.title
    , body =
        [ Style.globals
        , div
            [ class "layout"
            , classList
                [ ( "layout--visible"
                  , isLayoutVisible model.transition
                  )
                ]
            ]
            [ Html.Styled.map ContextSentMsg
                (Components.navbar
                    settings
                    Context.ToggleMenu
                    model.context
                )
            , Components.mainMenu
                settings
                model.context
            , div
                [ class "page"
                , classList
                    [ ( "page--visible"
                      , isPageVisible model.transition
                      )
                    ]
                ]
                page.body
            , Components.siteFooter settings
            ]
        ]
    }


viewPage : Model -> ( Document Msg, Settings )
viewPage { page } =
    case page of
        ProfileDetail content ->
            ( Page.ProfileDetail.view content
            , content.settings
            )

        NotFound ->
            ( { title = "Not Found | Demerly Architects", body = [] }
            , Settings.fallback
            )

        BadJson reason ->
            ( { title = "Uh oh | Demerly Architects", body = [ text reason ] }
            , Settings.fallback
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
