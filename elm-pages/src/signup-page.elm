import Browser
import Browser.Navigation exposing (load)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Encode as JEncode
import String

-- This is the source code for the signup page served as signup.html

main = 
 Browser.element { init = init, update = update, subscriptions = \_ -> Sub.none, view = view }

-- Change root URL as needed to route requests
rootUrl = "https://mac1xa3.ca/e/kostiukb/"

-- Model: Holds username, password from inputs and error message
type alias Model = {
    firstname : String, lastname : String, macid : String,
    password : String, confirmPassword : String, error : String }

type Msg = GetFirstname String  -- Change in firstname input
        | GetLastname String    -- Change in lastname input
        | GetMacID String    -- Change in macID input
        | GetPassword String    -- Change in password input
        | GetConfirmPassword String     -- Change in confirm password input
        | GetRegisterResponse (Result Http.Error String )  -- Retrieve the login response from backend
        | RegisterButtonPressed    -- Register button pressed

init : () -> ( Model, Cmd Msg )
init _ = ({ firstname = "", lastname = "", macid = "", password = "", 
    confirmPassword = "", error = "" }, Cmd.none)

-- Update
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model = case msg of
    -- Get values from input boxes
    GetFirstname fname -> ({ model | firstname = fname, error = "" }, Cmd.none )

    GetLastname lname -> ({ model | lastname = lname, error = "" }, Cmd.none )

    GetMacID macid -> ({ model | macid = macid, error = "" }, Cmd.none )

    GetPassword pass -> ({ model | password = pass, error = "" }, Cmd.none )

    GetConfirmPassword confirmpass -> (
        { model | confirmPassword = confirmpass, error = "" }, Cmd.none )

    RegisterButtonPressed -> ( model, registerPost model )

    GetRegisterResponse result ->
        case result of
            -- Login successful
            Ok "UserRegistered" ->
                ( { model | error = "Successfully registered!" }, load (rootUrl ++ "coursematch/static/home.html") )
            -- Failed to login
            Ok error ->
                ( { model | error = error }, Cmd.none )
            -- Any other error
            Err error ->
                ( handleError model error, Cmd.none )

-- Encode a JSON Post request to the backend to create a new user
jsonEncoder : Model -> JEncode.Value
jsonEncoder model = JEncode.object [
        ( "firstname", JEncode.string model.firstname ),
        ( "lastname", JEncode.string model.lastname ),
        ( "username" , JEncode.string model.macid ),
        ( "password" , JEncode.string model.password ),
        ( "confirm" , JEncode.string model.confirmPassword )
    ]

-- Post request to register
registerPost : Model -> Cmd Msg
registerPost model = Http.post {
        url = rootUrl ++ "coursematchauth/registeruser/",
        body = Http.jsonBody <| jsonEncoder model,
        expect = Http.expectString GetRegisterResponse
    }

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

-- View function generated from source-register.html
view : Model -> Html Msg
view model = div []
    [ node "link" [ href "vendor/fontawesome-free/css/all.min.css", rel "stylesheet", type_ "text/css" ]
        []
    , node "link" [ href "https://fonts.googleapis.com/css?family=Nunito:200,200i,300,300i,400,400i,600,600i,700,700i,800,800i,900,900i", rel "stylesheet" ]
        []
    , node "link" [ href "css/sb-admin-2.css", rel "stylesheet" ]
        []
    , div [ class "container" ]
        [ div [ class "card o-hidden border-0 shadow-lg my-5" ]
            [ div [ class "card-body p-0" ]
                [ div [ class "row" ]
                    [ div [ class "col-lg-5 d-none d-lg-block bg-register-image" ]
                        []
                    , div [ class "col-lg-7" ]
                        [ div [ class "p-5" ]
                            [ div [ class "text-center" ]
                                [ h1 [ class "h4 text-gray-900 mb-4" ]
                                    [ text "Create an Account!" ]
                                , p [ class (if model.error == "Successfully registered!" then "text-sucess" else "text-danger") ]
                                    [ text model.error ]
                                ]
                                -- Html form with input groups
                            , Html.form [ class "user" ]
                                [ div [ class "form-group row" ]
                                    [ div [ class "col-sm-6 mb-3 mb-sm-0" ]
                                        [ input [ class "form-control form-control-user", id "FirstName", placeholder "First Name", type_ "text", onInput GetFirstname ]
                                            []
                                        ]
                                    , div [ class "col-sm-6" ]
                                        [ input [ class "form-control form-control-user", id "LastName", placeholder "Last Name", type_ "text", onInput GetLastname ]
                                            []
                                        ]
                                    ]
                                , div [ class "form-group" ]
                                    [ input [ class "form-control form-control-user", id "MacId", placeholder "MacID", type_ "text", onInput GetMacID ]
                                        []
                                    ]
                                , div [ class "form-group row" ]
                                    [ div [ class "col-sm-6 mb-3 mb-sm-0" ]
                                        [ input [ class "form-control form-control-user", id "InputPassword", placeholder "Password", type_ "password", onInput GetPassword ]
                                            []
                                        ]
                                    , div [ class "col-sm-6" ]
                                        [ input [ class "form-control form-control-user", id "ConfirmPassword", placeholder "Confirm Password", type_ "password", onInput GetConfirmPassword ]
                                            []
                                        ]
                                    ]
                                , a ([ class "btn btn-primary btn-user btn-block", href "#"] ++ (if model.error == "" then [ onClick RegisterButtonPressed ] else []))
                                    [ text "Register Account" ]
                                ]
                            , hr []
                                []
                            , div [ class "text-center" ]
                                [ a [ class "small", href "login.html" ]
                                    [ text "Already have an account? Login!" ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]