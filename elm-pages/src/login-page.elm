import Browser
import Browser.Navigation exposing (load)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onCheck)
import Http
import Json.Encode as JEncode
import String

-- This is the source code for the login page served as login.html

main = 
 Browser.element { init = init, update = update, subscriptions = \_ -> Sub.none, view = view }

-- Change root URL as needed to route requests
rootUrl = "http://localhost:8000/"

-- Model: Holds username, password from inputs and error message
type alias Model = { macid : String, password : String, checked : Bool, error : String }

type Msg = GetMacID String      -- Change in username input
        | GetPassword String    -- Change in password input
        | GetChecked Bool       -- Checkbox changed
        | GetLoginResponse (Result Http.Error String )  -- Retrieve the login response from backend
        | LoginButtonPressed    -- Login button pressed

init : () -> ( Model, Cmd Msg )
init _ = ( { macid = "", password = "", checked = False, error = "" }, Cmd.none )

-- Encode a JSON Post request to the backend to login
jsonEncoder : Model -> JEncode.Value
jsonEncoder model = JEncode.object [
        ( "username" , JEncode.string model.macid ),
        ( "password" , JEncode.string model.password ),
        ( "remeber_user" , JEncode.bool model.checked )
    ]

-- Send the Post request to login
loginPost : Model -> Cmd Msg
loginPost model = Http.post {
        url = rootUrl ++ "coursematchauth/loginuser/",
        body = Http.jsonBody <| jsonEncoder model,
        expect = Http.expectString GetLoginResponse
    }

-- Update
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model = case msg of
    -- Get values from the input boxes
    GetMacID id -> 
        ( { model | macid = id, error = "" }, Cmd.none )

    GetPassword password ->
        ( { model | password = password, error = "" }, Cmd.none )
    
    GetChecked ischecked ->
        ( { model | checked = ischecked, error = "" }, Cmd.none )

    LoginButtonPressed ->
        ( model, loginPost model )
    -- Get the login response from the post
    GetLoginResponse result ->
        case result of
            -- Login successful
            Ok "LoggedIn" ->
                ( { model | error = "Login successful" }, load (rootUrl ++ "coursematch/static/home.html") ) 
            -- Failed to login
            Ok _ ->
                ( { model | error = "Failed to login, please try again" }, Cmd.none )
            -- Any other error
            Err error ->
                ( handleError model error, Cmd.none )

-- Handles all errors
handleError : Model -> Http.Error -> Model
handleError model error =
    case error of
        Http.BadUrl url ->
            { model | error = "Bad url: " ++ url }

        Http.Timeout ->
            { model | error = "Timeout error" }

        Http.NetworkError ->
            { model | error = "Network error" }

        Http.BadStatus i ->
            { model | error = "Bad status " ++ String.fromInt i }

        Http.BadBody body ->
            { model | error = "Bad body " ++ body }
    
-- Main view function, view source html at source-login.html
view : Model -> Html Msg
view model = div []
    [ node "link" [ href "vendor/fontawesome-free/css/all.min.css", rel "stylesheet", type_ "text/css" ]
        []
    , node "link" [ href "https://fonts.googleapis.com/css?family=Nunito:200,200i,300,300i,400,400i,600,600i,700,700i,800,800i,900,900i", rel "stylesheet" ]
        []
    , node "link" [ href "./css/sb-admin-2.css", rel "stylesheet" ]
        []
    , div [ class "container" ]
        [ div [ class "row justify-content-center" ]
            [ div [ class "col-xl-10 col-lg-12 col-md-9" ]
                [ div [ class "card o-hidden border-0 shadow-lg my-5" ]
                    [ div [ class "card-body p-0" ]
                        [ div [ class "row" ]
                            [ div [ class "col-lg-6 d-none d-lg-block bg-login-image" ]
                                []
                            , div [ class "col-lg-6" ]
                                [ div [ class "p-5" ]
                                    [ div [ class "text-center" ]
                                        [ h1 [ class "h4 text-gray-900 mb-4" ]
                                            [ text "Welcome Back!" ]
                                        ,
                                         p [ class (if model.error == "Login successful" then "text-success" else "text-danger") ]
                                                [ text model.error ]
                                        ]
                                    , Html.form [ class "user", id "loginForm" ]
                                        [ div [ class "form-group" ]
                                            [ input [ class "form-control form-control-user", id "InputId", placeholder "Enter your MacID...", type_ "text", onInput GetMacID ]
                                                []
                                            ]
                                        , div [ class "form-group" ]
                                            [ input [ class "form-control form-control-user", id "InputPassword", placeholder "Password", type_ "password", onInput GetPassword ]
                                                []
                                            ]
                                        , div [ class "form-group" ]
                                            [ div [ class "custom-control custom-checkbox small" ]
                                                [ input [ class "custom-control-input", id "customCheck", type_ "checkbox", onCheck GetChecked ]
                                                    []
                                                , label [ class "custom-control-label", for "customCheck" ]
                                                    [ text "Remember Me" ]
                                                ]
                                            ]
                                        , a ([ class "btn btn-primary btn-user btn-block", href "#", id "SubmitLogin" ] ++ (if model.error == "" then [ onClick LoginButtonPressed ] else [] ))
                                            [ text "Login" ]
                                        ]
                                    , hr []
                                        []
                                    , div [ class "text-center" ]
                                        [ a [ class "small", href "signup.html" ]
                                            [ text "Not Registered? Create an Account!" ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]