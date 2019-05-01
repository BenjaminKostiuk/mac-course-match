import Browser
import Html exposing (..)
import Browser.Navigation exposing (load)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as JEncode
import Json.Decode as JDecode
import List
import Http
import String

-- Source code for the main page of Course Match

main = 
 Browser.element { init = init, update = update, subscriptions = \_ -> Sub.none, view = view }
 
-- Change root URL as needed to route requests
rootUrl = "https://mac1xa3.ca/e/kostiukb/"

-- Base colors used in the css for various elements
colors = [ "danger", "info", "success", "warning", "secondary" ]

type alias Model = {
        location : Page, errorMessage : String, msgColor : String,
        editProfile : Bool,
        homeInfo : HomeInfo,            -- Information for home page
        profileInfo : ProfileInfo,      -- Information for profile page
        publicProfileInfo : PublicProfileInfo,  -- Info for current non-user profile being displayed
        courses : List Course,              -- List of user's courses
        searchCourses : List SearchCourse,  -- List of searched courses
        searchCoursesQuery : String,        -- Query string for searching courses
        searchProfiles : List PublicProfileInfo,       --- List of searched profiles
        searchProfilesQuery : String,                  -- Query string for searching profiles
        hoverCourse : Maybe SearchCourse,       -- Hovered course in find course
        hoverProfile : Maybe PublicProfileInfo, -- Hovered course in find profile
        following : List PublicProfileInfo      -- List of profiles that the user in following
    }

-- Home information
type alias HomeInfo = {
        firstname : String, 
        lastname : String, 
        following: Int,
        profileCompletion : Int,
        daysUntilEnd : Int,
        imgUrl : String
    }

-- Profile information
type alias ProfileInfo = {
        major : String,
        minor : String,
        year : Int,
        gpa : Float,
        favClasses : String,
        mood : String,
        bio : String
    }

-- Public Profile information
type alias PublicProfileInfo = {
        uname : String,
        fullname : String,
        imgUrl : String,
        info : ProfileInfo,
        courses : List Course
    }

-- Information on a course
type alias Course = {
        code : String,
        department : String,
        lecture : Maybe Class,
        tutorial : Maybe Class,
        lab : Maybe Class
    }

-- Store search results for courses
type alias SearchCourse = {
        code : String,
        department : String,
        lectures : List Class,
        tutorials : List Class,
        labs : List Class
    }

-- Information for a class
type alias Class = {
        section : String, 
        prof : String,
        location : String, 
        times : String
    }

type Msg = GoTo Page
        | Logout
        | GetResponseString (Result Http.Error String) -- Http Get Response (String)
        | HomeInfoResponse (Result Http.Error HomeInfo)    -- Http JSON Post & Get Responses 
        | ProfileInfoResponse (Result Http.Error ProfileInfo)
        | CoursesReponse (Result Http.Error (List Course))
        | SearchCoursesResponse (Result Http.Error (List SearchCourse))
        | SearchProfilesResponse (Result Http.Error (List PublicProfileInfo))
        | GetFollowingResponse (Result Http.Error (List PublicProfileInfo))
        | SearchForCourse String        -- Search course
        | SearchForProfile String       -- Search profiles
        | SearchForFollowing String     -- Filter following
        | Follow String             -- Follow a student by their username
        | Unfollow String           -- UnFollow a student by their username
        | UnfollowAll               -- Unfollow all a student by their username
        | GetUserCourses String     -- Get a user's courses
        | AddCourse String
        | RemoveCourse String
        | HoverOnCourse SearchCourse        -- Hover over a searched course
        | HoverOffCourse                    -- Hover off a searched course
        | HoverOnProfile PublicProfileInfo  -- Hover over a searched profile
        | HoverOffProfile                   -- Hover off a searched profile
        | ChangePicture String              -- Change profile picture
        | EditProfileInfo String String     -- Edit profile info (key value)
        | EditProfileButtonPressed          -- Switch to edit mode
        | SaveProfileButtonPressed          -- Save profile changes

-- Pages in main app
type Page = Home    
        | MyCourses
        | MyProfile
        | UpdatePicture
        | Following
        | FindStudent
        | FindCourse
        | CompareSchedules
        | PublicProfile PublicProfileInfo
        | ComingSoon

-- Initialize all fields to default or empty
init : () -> ( Model, Cmd Msg )
init _ = ( { location = Home, errorMessage = "", msgColor = "text-danger", editProfile = False,
            homeInfo = { firstname = "", lastname = "", following = 0, profileCompletion = 0, daysUntilEnd = 0, imgUrl = "profile1.svg" },
            profileInfo = { major = "", minor = "", year = 0, gpa = 1.0, favClasses = "", mood = "", bio = "" },
            publicProfileInfo = { uname = "", fullname = "", imgUrl = "", info = { major = "", minor = "", year = 1, gpa = 1.0, favClasses = "", mood = "", bio = ""}, courses = [] },
            courses = [], searchCourses = [], searchProfiles = [],
            searchProfilesQuery = "", searchCoursesQuery = "",
            hoverCourse = Nothing, hoverProfile = Nothing, following = [] }, getUserAuth)

-- Encode a JSON Post request to the backend to change profile information
profileInfoJEncoder : Model -> JEncode.Value
profileInfoJEncoder model = JEncode.object [
        ( "major" , JEncode.string model.profileInfo.major ),
        ( "minor" , JEncode.string model.profileInfo.minor ),
        ( "year" , JEncode.int model.profileInfo.year ),
        ( "gpa" , JEncode.float model.profileInfo.gpa ),
        ( "favClasses" , JEncode.string model.profileInfo.favClasses ),
        ( "mood" , JEncode.string model.profileInfo.mood ),
        ( "bio" , JEncode.string model.profileInfo.bio )
    ]
-- Send a post with the new profile information
saveProfilePost : Model ->  Cmd Msg
saveProfilePost model = Http.post {
        url = rootUrl ++ "coursematchapp/saveprofileinfo/",
        body = Http.jsonBody <| profileInfoJEncoder model,
        expect = Http.expectString GetResponseString
    }

-- Decode a HomeInfo object with JSON information
homeJSONDecoder : JDecode.Decoder HomeInfo
homeJSONDecoder = 
    JDecode.map6 HomeInfo
        (JDecode.field "firstname" JDecode.string)
        (JDecode.field "lastname" JDecode.string)
        (JDecode.field "following" JDecode.int)
        (JDecode.field "profileCompletion" JDecode.int)
        (JDecode.field "daysUntilEnd" JDecode.int)
        (JDecode.field "imgUrl" JDecode.string)

-- Decode a profile Json Object
profileJSONDecoder : JDecode.Decoder ProfileInfo
profileJSONDecoder = 
    JDecode.map7 ProfileInfo
        (JDecode.field "major" JDecode.string)
        (JDecode.field "minor" JDecode.string)
        (JDecode.field "year" JDecode.int)
        (JDecode.field "gpa" JDecode.float)
        (JDecode.field "favClasses" JDecode.string)
        (JDecode.field "mood" JDecode.string)
        (JDecode.field "bio" JDecode.string)

-- Decode a public profile info object
publicProfileJSONDecoder : JDecode.Decoder (List PublicProfileInfo)
publicProfileJSONDecoder = 
    JDecode.field "data" 
    (JDecode.list
        ((JDecode.map5 PublicProfileInfo
                (JDecode.field "uname" JDecode.string)
                (JDecode.field "fullname" JDecode.string)
                (JDecode.field "imgUrl" JDecode.string)
                (JDecode.field "info" (profileJSONDecoder))
                (coursesJSONDecoder)
        ))
    )

classJSONDecoder : JDecode.Decoder Class
classJSONDecoder = 
    JDecode.map4 Class
        (JDecode.field "section" JDecode.string)
        (JDecode.field "prof" JDecode.string)
        (JDecode.field "location" JDecode.string)
        (JDecode.field "times" JDecode.string)

-- Decode a list of courses in json
coursesJSONDecoder : JDecode.Decoder (List Course)
coursesJSONDecoder = 
    JDecode.field "courses" 
        (JDecode.list 
            ((JDecode.map5 Course)
                (JDecode.field "code" JDecode.string)
                (JDecode.field "department" JDecode.string)
                (JDecode.field "lecture" (JDecode.nullable (classJSONDecoder)))
                (JDecode.field "tutorial" (JDecode.nullable (classJSONDecoder)))
                (JDecode.field "lab" (JDecode.nullable (classJSONDecoder)))
            ))

-- Decode the list of search results for courses
searchCoursesJSONDecoder : JDecode.Decoder (List SearchCourse)
searchCoursesJSONDecoder = 
    JDecode.field "data"
        (JDecode.list
            ((JDecode.map5 SearchCourse)
                (JDecode.field "code" JDecode.string)
                (JDecode.field "department" JDecode.string)
                (JDecode.field "lectures" (JDecode.list (classJSONDecoder)))
                (JDecode.field "tutorials" (JDecode.list (classJSONDecoder)))
                (JDecode.field "labs" (JDecode.list (classJSONDecoder))) 
            )
        )

-- All backend calls to the Django Database in the form fo Cmd Msg
-- Get basic user info
getUserInfo : Cmd Msg
getUserInfo =
    Http.get { 
        url = rootUrl ++ "coursematchauth/getuserinfo/",
        expect = Http.expectJson HomeInfoResponse homeJSONDecoder
        }
-- Get user's profile info
getProfileInfo : Cmd Msg
getProfileInfo = 
    Http.get {
        url = rootUrl ++ "coursematchapp/getprofileinfo/",
        expect = Http.expectJson ProfileInfoResponse profileJSONDecoder
    }
-- Get user's courses
getCourses : String -> Cmd Msg
getCourses query = 
    Http.post {
        url = rootUrl ++ "coursematchapp/getusercourses/",
        body = Http.stringBody "application/x-www-form-urlencoded" ("code=" ++ query),
        expect = Http.expectJson CoursesReponse coursesJSONDecoder
    }
-- Get user's following list
getFollowing : String -> Cmd Msg
getFollowing query = 
    Http.post {
        url = rootUrl ++ "coursematchapp/getfollowing/",
        body = Http.stringBody "application/x-www-form-urlencoded" ("query=" ++ query),
        expect = Http.expectJson GetFollowingResponse publicProfileJSONDecoder
    }
-- Send a msg to unfollow a student
unfollowStudent : String -> Cmd Msg
unfollowStudent username = 
    Http.post {
        url = rootUrl ++ "coursematchapp/unfollowstudent/",
        body = Http.stringBody "application/x-www-form-urlencoded" ("username=" ++ username),
        expect = Http.expectString GetResponseString
    }
-- Unfollow all student's the user is currently following
unfollowAll : Cmd Msg
unfollowAll = 
    Http.get {
        url = rootUrl ++ "coursematchapp/unfollowall/",
        expect = Http.expectString GetResponseString
    }
-- Make a search in find courses based off a query
searchCourses : String -> Cmd Msg
searchCourses query = 
    Http.get {
        url = rootUrl ++ "coursematchapp/searchcourses/?code=" ++ query,
        expect = Http.expectJson SearchCoursesResponse searchCoursesJSONDecoder
    }
-- Make a search in find student 
searchProfiles : String -> Cmd Msg
searchProfiles query = 
    Http.get {
        url = rootUrl ++ "coursematchapp/searchprofiles/?query=" ++ query,
        expect = Http.expectJson SearchProfilesResponse publicProfileJSONDecoder
    }
-- Add a course by code
addCourse : String -> Cmd Msg
addCourse code = 
    Http.post {
        url = rootUrl ++ "coursematchapp/addcourse/",
        body = Http.stringBody "application/x-www-form-urlencoded" ("code=" ++ code),
        expect = Http.expectString GetResponseString
    }
-- Remove a course by code
removeCourse : String -> Cmd Msg
removeCourse code = 
    Http.post {
        url = rootUrl ++ "coursematchapp/removecourse/",
        body = Http.stringBody "application/x-www-form-urlencoded" ("code=" ++ code),
        expect = Http.expectString GetResponseString
    }
-- Follow a student from their username
followStudent : String -> Cmd Msg
followStudent username = 
    Http.post {
        url = rootUrl ++ "coursematchapp/followuser/",
        body = Http.stringBody "application/x-www-form-urlencoded" ("username=" ++ username),
        expect = Http.expectString GetResponseString
    }
-- Update the user's avatar
updatePicture : String -> Cmd Msg
updatePicture imgUrl = 
    Http.get {
        url = rootUrl ++ "coursematchapp/updatepicture/?url=" ++ imgUrl,
        expect = Http.expectString GetResponseString
    }
-- Check if the user is authenticated
getUserAuth : Cmd Msg
getUserAuth = 
    Http.get { 
            url = rootUrl ++ "coursematchauth/isauth/",
            expect = Http.expectString GetResponseString
        }
-- Logout the user
logoutRequest : Cmd Msg
logoutRequest = Http.get {
        url = rootUrl ++ "coursematchauth/logoutuser/",
        expect = Http.expectString GetResponseString
    }

-- Update a profile field helper function
updateProfile : String -> String -> ProfileInfo -> ProfileInfo
updateProfile key value profileInfo = case key of 
    "Major" -> { profileInfo | major = value }
    "Minor" -> { profileInfo | minor = value }
    "Year" -> { profileInfo | year = case String.toInt value of 
                                            Just x -> x
                                            Nothing -> 1 }
    "GPA" -> { profileInfo | gpa = case String.toFloat value of 
                                            Just x -> x
                                            Nothing -> 1.0 }
    "FavClasses" -> { profileInfo | favClasses = value }
    "Mood" -> { profileInfo | mood = value }
    _ -> { profileInfo | bio = value }

-- Update
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model = case msg of
    -- Go to a Page and update accordingly
    GoTo Home -> ({ model | location = Home, errorMessage = "" }, getUserInfo )
    GoTo MyProfile -> ({ model | location = MyProfile, errorMessage = "" }, getProfileInfo)
    GoTo MyCourses -> ({ model | location = MyCourses, errorMessage = "" }, getCourses "")
    GoTo FindCourse -> ({ model | location = FindCourse, errorMessage = "", searchCourses = [], searchCoursesQuery = "" }, Cmd.none )
    GoTo FindStudent -> ({ model | location = FindStudent, errorMessage = "", searchProfiles = [], searchProfilesQuery = "" }, Cmd.none )
    GoTo Following -> ({ model | location = Following, errorMessage = "" }, getFollowing "")
    GoTo (PublicProfile profile) -> ({ model | location = PublicProfile profile, publicProfileInfo = profile, errorMessage = "" }, Cmd.none )
    GoTo page -> ({ model | location = page, editProfile = False, errorMessage = "" }, Cmd.none)

    EditProfileInfo key value -> ({ model | profileInfo = updateProfile key value model.profileInfo }, Cmd.none)
    -- Search for course, profiles, following by query
    SearchForCourse query -> ( { model | searchCoursesQuery = query }, searchCourses query )
    SearchForProfile query -> ( { model | searchProfilesQuery = query }, searchProfiles query )
    SearchForFollowing query -> ( model, getFollowing query )
    -- Basic operations, ADD, REMOVE, FOLLOW, UNFOLLOW, UNFOLLOWALL
    GetUserCourses query -> ( model, getCourses query )
    AddCourse code -> ( model, addCourse code )
    RemoveCourse code -> ( model, removeCourse code )
    Follow username -> ( model, followStudent username )
    Unfollow username -> ( model, unfollowStudent username )
    UnfollowAll -> ({ model | following = [] }, unfollowAll )
    -- Change picture on profile
    ChangePicture url -> ({ model | location = MyProfile, homeInfo = { 
        imgUrl = url, firstname = model.homeInfo.firstname,
        lastname = model.homeInfo.lastname, following = model.homeInfo.following,
        profileCompletion = model.homeInfo.profileCompletion, daysUntilEnd = model.homeInfo.daysUntilEnd } }, updatePicture url )
    -- Switch between edit and save mode on profile
    EditProfileButtonPressed -> ({ model | editProfile = True }, Cmd.none )
    SaveProfileButtonPressed -> ( model , saveProfilePost model )
    -- Hover over courses or profiles and update
    HoverOnCourse course -> ({ model | hoverCourse = Just course }, Cmd.none )
    HoverOffCourse -> ({ model | hoverCourse = Nothing }, Cmd.none )
    HoverOnProfile profile -> ({ model | hoverProfile = Just profile }, Cmd.none )
    HoverOffProfile -> ({ model | hoverProfile = Nothing }, Cmd.none )
    -- Logout
    Logout -> ( model, logoutRequest )
    -- Get reponse from server and update component in model accordingly
    HomeInfoResponse result ->
        case result of 
            Ok newHomeInfo -> ({ model | homeInfo = newHomeInfo }, getFollowing "" )
            Err error -> ( handleError model error , Cmd.none )

    ProfileInfoResponse result ->
        case result of 
            Ok newProfileInfo -> ({ model | profileInfo = newProfileInfo }, Cmd.none )
            Err error -> ( handleError model error, Cmd.none )
    
    CoursesReponse result ->
        case result of 
            Ok newCourses -> ({ model | courses = newCourses }, Cmd.none )
            Err error -> ( handleError model error, Cmd.none )
    
    SearchCoursesResponse result ->
        case result of 
            Ok searchResults -> ({ model | searchCourses = searchResults }, Cmd.none )
            Err error -> ( handleError model error, Cmd.none )

    SearchProfilesResponse result ->
        case result of 
            Ok searchResults -> ({ model | searchProfiles = searchResults }, Cmd.none )
            Err error -> ( handleError model error, Cmd.none )
    
    GetFollowingResponse result ->
        case result of 
            Ok followingResults -> ({ model | following = followingResults }, getCourses "" )
            Err error -> ( handleError model error, Cmd.none )
    -- Get string response and update accordingly
    GetResponseString result ->
        case result of 
            -- Redirect if not authenticated
            Ok "NotAuthenticated" -> ({ model | errorMessage = "NotAuthenticated", msgColor = "text-danger"}, load "index.html" )
            -- Get homeInfo is user is authenticated
            Ok "Authenticated" -> ( model, getUserInfo)
            --Redirect back to index page
            Ok "RedirectOnly" -> ({ model | errorMessage = "redirecting...", msgColor = "text-danger"}, load "index.html" )
            -- Logout confirmation message
            Ok "LoggedOut" -> ({ model | errorMessage = "loggedout", msgColor = "text-success" }, load "index.html")
            -- Update profile message and call updated information
            Ok "Profile Updated" -> ({ model | errorMessage = "Profile updated", editProfile = False, msgColor = "text-success"}, Cmd.none )
            -- Update profile picture message information
            Ok "Profile Picture Updated" -> ({ model | errorMessage = "Profile picture updated", editProfile = False, msgColor = "text-success"}, searchProfiles "" )
            -- Add course confirmation and get updated course list
            Ok "Course Added" -> ({ model | errorMessage = "Course Added", msgColor = "text-success" }, getUserInfo )
            -- Remove course and get updated course list
            Ok "Course Removed" -> ({ model | errorMessage = "Course Removed", msgColor = "text-success" }, getCourses "")
            -- Follow student confirmation
            Ok "Followed Student" -> ({ model | errorMessage = "Followed Student", msgColor = "text-success" }, getUserInfo )
            -- Unfollow a student confirmation
            Ok "Unfollowed Student" -> ({ model | errorMessage = "Unfollowed Student", msgColor = "text-success" }, getFollowing "" )
            -- Unfollow all students
            Ok "Unfollowed All" -> ({ model | errorMessage = "Unfollowed All", msgColor = "text-success" }, getFollowing "" )
            -- Any other error message
            Ok message -> ( { model | errorMessage = message, msgColor = "text-danger" }, Cmd.none )
            -- Handle any errors
            Err error -> ( handleError model error , Cmd.none )

-- Handles all errors
handleError : Model -> Http.Error -> Model
handleError model error =
    case error of
        Http.BadUrl url ->
            { model | errorMessage = "Bad url: " ++ url, msgColor = "text-danger" }

        Http.Timeout ->
            { model | errorMessage = "Timeout error", msgColor = "text-danger" }

        Http.NetworkError ->
            { model | errorMessage = "Network error", msgColor = "text-danger" }

        Http.BadStatus i ->
            { model | errorMessage = "Bad status " ++ String.fromInt i, msgColor = "text-danger" }

        Http.BadBody body ->
            { model | errorMessage = "Bad body " ++ body, msgColor = "text-danger" }

-- Home view function generated from source-home-page.html
homeView : Model -> Html Msg
homeView model = div []
        [ h1 [ class "h3 mb-0 text-gray-800" ]
            [ text ("Hello " ++ model.homeInfo.firstname ++ "!")]
        , h3 [ class ("h4 mb-4 " ++ model.msgColor) ]
            [ text model.errorMessage ]
        , div [ class "row" ]
            [ div [ class "col-xl-3 col-md-6 mb-4" ]
                [ div [ class "card border-left-primary shadow h-auto py-2" ]
                    [ div [ class "card-body" ]
                        [ div [ class "row no-gutters align-items-center" ]
                            [ div [ class "col mr-2" ]
                                [ div [ class "text-xs font-weight-bold text-primary text-uppercase mb-1" ]
                                    [ text "Courseload" ]
                                , div [ class "h5 mb-0 font-weight-bold text-gray-800" ]
                                    [ text (String.fromInt (List.length model.courses)) ]
                                ]
                            , div [ class "col-auto" ]
                                [ i [ class "fas fa-calendar fa-2x text-gray-300" ]
                                    []
                                ]
                            ]
                        ]
                    ]
                ]
            , div [ class "col-xl-3 col-md-6 mb-4" ]
                [ div [ class "card border-left-secondary shadow h-auto py-2" ]
                    [ div [ class "card-body" ]
                        [ div [ class "row no-gutters align-items-center" ]
                            [ div [ class "col mr-2" ]
                                [ div [ class "text-xs font-weight-bold text-secondary text-uppercase mb-1" ]
                                    [ text "Following" ]
                                , div [ class "h5 mb-0 font-weight-bold text-gray-800" ]
                                    [ text (String.fromInt model.homeInfo.following ) ]
                                ]
                            , div [ class "col-auto" ]
                                [ i [ class "fas fa-users fa-2x text-gray-300" ]
                                    []
                                ]
                            ]
                        ]
                    ]
                ]
            , div [ class "col-xl-3 col-md-6 mb-4" ]
                [ div [ class "card border-left-info shadow h-auto py-2" ]
                    [ div [ class "card-body" ]
                        [ div [ class "row no-gutters align-items-center" ]
                            [ div [ class "col mr-2" ]
                                [ div [ class "text-xs font-weight-bold text-info text-uppercase mb-1" ]
                                    [ text "Profile Completion" ]
                                , div [ class "row no-gutters align-items-center" ]
                                    [ div [ class "col-auto" ]
                                        [ div [ class "h5 mb-0 mr-3 font-weight-bold text-gray-800" ]
                                            [ text ((String.fromInt model.homeInfo.profileCompletion) ++ "%") ]
                                        ]
                                    , div [ class "col" ]
                                        [ div [ class "progress progress-sm mr-2" ]
                                            [ div [ attribute "aria-valuemax" "100", attribute "aria-valuemin" "0", attribute "aria-valuenow" (String.fromInt model.homeInfo.profileCompletion), class "progress-bar bg-info", attribute "role" "progressbar", attribute "style" ("width:" ++ (String.fromInt model.homeInfo.profileCompletion) ++ "%") ]
                                                []
                                            ]
                                        ]
                                    ]
                                ]
                            , div [ class "col-auto" ]
                                [ i [ class "fas fa-clipboard-list fa-2x text-gray-300" ]
                                    []
                                ]
                            ]
                        ]
                    ]
                ]
            , div [ class "col-xl-3 col-md-6 mb-4" ]
                [ div [ class "card border-left-warning shadow h-auto py-2" ]
                    [ div [ class "card-body" ]
                        [ div [ class "row no-gutters align-items-center" ]
                            [ div [ class "col mr-2" ]
                                [ div [ class "text-xs font-weight-bold text-warning text-uppercase mb-1" ]
                                    [ text "Days till end of term" ]
                                , div [ class "h5 mb-0 font-weight-bold text-gray-800" ]
                                    [ text (String.fromInt model.homeInfo.daysUntilEnd) ]
                                ]
                            , div [ class "col-auto" ]
                                [ i [ class "fas fa-clock fa-2x text-gray-300" ]
                                    []
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        , div [ class "row" ]
            [ div [ class "col-xl-8 col-lg-7" ]
                [ div [ class "card shadow mb-1" ]
                    [ div [ class "card-header py-3 d-flex flex-row align-items-center justify-content-between" ]
                        [ h6 [ class "m-0 font-weight-bold text-primary" ]
                            [ text "Following" ]
                        ]
                    ]
                , div [] (List.map (\followProfile -> div [ class "card shadow mb-1" ]
                        [ div [ class "card-header py-3 mb-0 h-auto" ]
                            [ div [ class "mb-0 d-inline-flex" ]
                                [ h6 [ class "font-weight-bold text-info mb-0" ]
                                    [ text followProfile.fullname
                                    , p [ class "mb-0 text-gray-500 d-block" ]
                                        [ text (followProfile.info.major ++ case followProfile.info.year of
                                                                                    1 -> " I"
                                                                                    2 -> " II"
                                                                                    3 -> " III"
                                                                                    _ -> " IV")  ]
                                    ]
                                ]
                            , a [ class "mr-2 btn btn-info btn-icon-split float-right", href "#", onClick (GoTo (PublicProfile followProfile)) ]
                                [ span [ class "icon text-white-50" ]
                                    [ i [ class "fas fa-user mt-1" ]
                                        []
                                    ]
                                , span [ class "text" ]
                                    [ text "View Full Profile" ]
                                ]
                            ]
                        ]) model.following)
                ]
            , div [ class "col-xl-4 col-lg-5" ]
                [ div [ class "card shadow mb-1" ]
                    [ div [ class "card-header py-3 d-flex flex-row align-items-center justify-content-between" ]
                        [ h6 [ class "m-0 font-weight-bold text-primary" ]
                            [ text "My Courses" ]
                        ]
                    ]
                , div [] (List.map2 (\course color -> 
                            div [ class ("card bg-" ++ color ++ " text-white shadow mb-1") ]
                                [ div [ class "card-body" ]
                                    [ text course.code ]
                                ]) model.courses (List.concat (List.repeat (List.length model.courses) colors)))
                ]
            ]
        , div [ class "row mt-4" ]
            [ div [ class "col-xl-12 col-lg-7" ]
                [ div [ class "card shadow mb-1" ]
                    [ div [ class "card-header py-3 d-flex flex-row align-items-center justify-content-between" ]
                        [ h6 [ class "m-0 font-weight-bold text-primary" ]
                            [ text "Popular Courses" ]
                        ]
                    ]
                ]
            , div [ class "col-xl-4 col-lg-5" ]
                [ div [ class "card bg-primary text-white shadow mb-1" ]
                    [ div [ class "card-body" ]
                        [ text "Math 1ZB3" ]
                    ]
                ]
            , div [ class "col-xl-4 col-lg-5" ]
                [ div [ class "card bg-danger text-white shadow mb-1" ]
                    [ div [ class "card-body" ]
                        [ text "Math 1ZC3" ]
                    ]
                ]
            , div [ class "col-xl-4 col-lg-5" ]
                [ div [ class "card bg-success text-white shadow mb-1" ]
                    [ div [ class "card-body" ]
                        [ text "COMPSCI 1MD3" ]
                    ]
                ]
            , div [ class "col-xl-4 col-lg-5" ]
                [ div [ class "card bg-info text-white shadow mb-1" ]
                    [ div [ class "card-body" ]
                        [ text "COMPSCI 1XA3" ]
                    ]
                ]
            , div [ class "col-xl-4 col-lg-5" ]
                [ div [ class "card bg-secondary text-white shadow mb-1" ]
                    [ div [ class "card-body" ]
                        [ text "ECON 1BB3" ]
                    ]
                ]
            , div [ class "col-xl-4 col-lg-5" ]
                [ div [ class "card bg-warning text-white shadow mb-1" ]
                    [ div [ class "card-body" ]
                        [ text "ASTRO 1AA3" ]
                    ]
                ]
            ]
        ]

-- Coming soon page for all functionality to be implemented
comingSoonView : Model -> Html Msg
comingSoonView model = div [] [
        h1 [ class "h3 mb-0 text-gray-800" ]
            [ text ("Coming Soon!")]
    ]

-- Follow view function generated from source-following.html
followingView : Model -> Html Msg
followingView model = div []
        [ h1 [ class "h3 mb-4 text-gray-800" ]
            [ text "Following" ]
        , div [ class "row mb-4" ]
            [ Html.form [ class "col-lg-6 d-none d-sm-inline-block form-inline my-2 my-md-0 navbar-search-classes" ]
                [ div [ class "input-group bg-white" ]
                    [ input [ onInput SearchForFollowing, attribute "aria-describedby" "basic-addon2", attribute "aria-label" "Search", class "form-control border-0 small", placeholder "Filter students...", type_ "text" ]
                        []
                    , div [ class "input-group-append" ]
                        [ button [ class "btn btn-primary", type_ "button" ]
                            [ i [ class "fas fa-search fa-sm" ]
                                []
                            ]
                        ]
                    ]
                ]
            , div [ class "col-lg-6" ]
                [ a [ class "ml-0 btn btn-danger btn-icon-split float-left", href "#", onClick UnfollowAll ]
                    [ span [ class "icon text-white-50" ]
                        [ i [ class "fas fa-times mt-1" ]
                            []
                        ]
                    , span [ class "text" ]
                        [ text "Unfollow all" ]
                    ]
                ]
            ]
        , div [ class "row" ]
            (if model.following == [] then
                [div []
                [ img [ alt "", class "img-fluid p-4 img-center", src "img/undraw_online_friends_x73e.svg", attribute "style" "width: 80%;" ]
                    []
                ]]
            else
            ([ div [ class "col-lg-12 h-100" ]
                (List.map (\followProfile -> div [ class "card card-result shadow mb-1" ]
                    [ div [ class "card-header py-3 mb-0 h-auto" ]
                        [ div [ class "mb-0 d-inline-flex" ]
                            [ h6 [ class "font-weight-bold text-info mb-0" ]
                                [ text followProfile.fullname
                                , p [ class "mb-0 text-gray-500 d-block" ]
                                    [ text (followProfile.info.major ++ (
                                    case followProfile.info.year of 
                                        1 -> " I"
                                        2 -> " II"
                                        3 -> " III"
                                        _ -> " IV"
                                    ))]
                                ]
                            ]
                        , a [ class "mr-2 btn btn-info btn-icon-split float-right", href "#", onClick (GoTo (PublicProfile followProfile)) ]
                            [ span [ class "icon text-white-50" ]
                                [ i [ class "fas fa-user mt-1" ]
                                    []
                                ]
                            , span [ class "text" ]
                                [ text "View Full Profile" ]
                            ]
                        , a [ class "mr-2 btn btn-secondary btn-icon-split float-right", href "#", onClick (Unfollow followProfile.uname) ]
                            [ span [ class "icon text-white-50" ]
                                [ i [ class "fas fa-user-times mt-1" ]
                                    []
                                ]
                            , span [ class "text" ]
                                [ text "Unfollow" ]
                            ]
                        ]
                    ]
                    ) model.following)
            ]))
        ]

-- Public profile function generated with elements from profilepage.html
publicProfileView : Model -> Html Msg
publicProfileView model = div []
    [ h1 [ class "h3 mb-0 text-gray-800" ]
        [ text "View Profile" ]
    , h3 [ class ("h4 mb-4 " ++ model.msgColor) ]
    [ text model.errorMessage ]
    , div [ class "row" ]
        [ div [ class "col-lg-3 mb-5" ]
            [ div [ class "text-center" ]
                [ img [ alt "", class "img-fluid px-3 px-sm-4 mt-3 mb-4 w-100", src ("img/" ++ model.publicProfileInfo.imgUrl) ]
                    []
                ]
            , a [ class "ml-4 btn btn-info btn-icon-split", href "#", onClick (Follow model.publicProfileInfo.uname) ]
                [ span [ class "icon text-white-50" ]
                    [ i [ class "fas fa-user-friends mt-1" ]
                        []
                    ]
                , span [ class "text" ]
                    [ text "Follow Student" ]
                ]
            ]
        , div [ class "col-lg-9 mb-4" ]
            [ div [ class "card shadow mb-4" ]
                [ div [ class "card-header py-3" ]
                    [ h4 [ class "m-0 font-weight-bold text-primary" ]
                        [ text model.publicProfileInfo.fullname ]
                    ]
                , div [ class "card-body" ]
                    [ div [ class "row" ]
                        [ div [ class "col-4 ml-2" ]
                            [ p []
                                [ b []
                                    [ text "Major: " ]
                                , text model.publicProfileInfo.info.major
                                ]
                            , p []
                                [ b []
                                    [ text "Minor(s): " ]
                                , text model.publicProfileInfo.info.minor
                                ]
                            , p []
                                [ b []
                                    [ text "Year: " ]
                                , text (String.fromInt (model.publicProfileInfo.info.year))
                                ]
                            , p []
                                [ b []
                                    [ text "GPA: " ]
                                , text (String.fromFloat (model.publicProfileInfo.info.gpa))
                                ]
                            , p []
                                [ b []
                                    [ text "Favorite Classes: " ]
                                , br []
                                    []
                                , text model.publicProfileInfo.info.favClasses
                                ]
                            ]
                        , div [ class "col-7 ml-4" ]
                            [ p []
                                [ b []
                                    [ text "Mood: " ]
                                , text model.publicProfileInfo.info.mood
                                ]
                            , p []
                                [ b []
                                    [ text "Bio: " ]
                                , text model.publicProfileInfo.info.bio
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        ,
        (if model.publicProfileInfo.courses == [] then (div [] [text "empty"]) else (div [] []))
        , div [ class "row mb-4" ]
            ([ div [ class "col-xl-12 col-lg-7" ]
                [ div [ class "card shadow mb-1" ]
                    [ div [ class "card-header py-3 d-flex flex-row align-items-center justify-content-between" ]
                        [ h6 [ class "m-0 font-weight-bold text-primary" ]
                            [ text (model.publicProfileInfo.fullname ++ "'s Courses") ]
                        ]
                    ]
                ]
             ] ++ (List.map2 (\course color -> div [ class "col-xl-4 col-lg-5" ]
                [ div [ class ("card bg-" ++ color ++ " text-white shadow mb-1") ]
                    [ div [ class "card-body" ]
                        [ div [ class "mb-0 d-inline-flex" ]
                            [ h6 [ class "font-weight-bold text-white mb-0" ]
                                ([ text course.code
                                , br []
                                    []
                                ] ++ 
                                (case course.lecture of
                                    Just lec -> [p [ class "mb-0 d-inline-flex text-gray-white d-block mr-4 mt-1 section-outline" ]
                                                    [ text lec.section ]]
                                    Nothing -> [])
                                ++
                                (case course.tutorial of
                                    Just tut -> [p [ class "mb-0 d-inline-flex text-gray-white d-block mr-4 mt-1 section-outline" ]
                                                    [ text tut.section ]]
                                    Nothing -> []
                                )
                                ++
                                (case course.lab of 
                                    Just lab -> [p [ class "mb-0 d-inline-flex text-gray-white d-block mr-4 mt-1 section-outline" ]
                                                    [ text lab.section ]]
                                    Nothing -> []
                                ))
                            ]
                        ]
                    ]
                ]
                ) model.publicProfileInfo.courses (List.concat (List.repeat (List.length model.publicProfileInfo.courses) colors))))


    ]

-- Update picture with all profile avatars to choose from
updatePictureView : Model -> Html Msg
updatePictureView model = div []
        [ h1 [ class "h3 mb-0 text-gray-800" ]
            [ text "Update Profile" ]
        , h3 [ class ("h4 mb-4 " ++ model.msgColor) ]
            [ text model.errorMessage ]
        , div [ class "row" ]
            [ div [ class "col-lg-3 mb-5" ]
                [ div [ class "text-center" ]
                    [ img [ onClick (ChangePicture "profile1.svg"), alt "", class "img-fluid px-3 px-sm-4 mt-3 mb-4 w-100", src "img/profile1.svg" ]
                        []
                    ]
                ]
            , div [ class "col-lg-3 mb-5" ]
                [ div [ class "text-center" ]
                    [ img [ onClick (ChangePicture "profile2.svg"), alt "", class "img-fluid px-3 px-sm-4 mt-3 mb-4 w-100", src "img/profile2.svg" ]
                        []
                    ]
                ]
            , div [ class "col-lg-3 mb-5" ]
                [ div [ class "text-center" ]
                    [ img [ onClick (ChangePicture "profile3.svg"), alt "", class "img-fluid px-3 px-sm-4 mt-3 mb-4 w-100", src "img/profile3.svg" ]
                        []
                    ]
                ]
            , div [ class "col-lg-3 mb-5" ]
                [ div [ class "text-center" ]
                    [ img [ onClick (ChangePicture "profile4.svg"), alt "", class "img-fluid px-3 px-sm-4 mt-3 mb-4 w-100", src "img/profile4.svg" ]
                        []
                    ]
                ]
            , div [ class "col-lg-3 mb-5" ]
                [ div [ class "text-center" ]
                    [ img [ onClick (ChangePicture "profile5.svg"), alt "", class "img-fluid px-3 px-sm-4 mt-3 mb-4 w-100", src "img/profile5.svg" ]
                        []
                    ]
                ]
            , div [ class "col-lg-3 mb-5" ]
                [ div [ class "text-center" ]
                    [ img [ onClick (ChangePicture "profile6.svg"), alt "", class "img-fluid px-3 px-sm-4 mt-3 mb-4 w-100", src "img/profile6.svg" ]
                        []
                    ]
                ]
            , div [ class "col-lg-3 mb-5" ]
                [ div [ class "text-center" ]
                    [ img [ onClick (ChangePicture "profile7.svg"), alt "", class "img-fluid px-3 px-sm-4 mt-3 mb-4 w-100", src "img/profile7.svg" ]
                        []
                    ]
                ]
            , div [ class "col-lg-3 mb-5" ]
                [ div [ class "text-center" ]
                    [ img [ onClick (ChangePicture "profile8.svg"), alt "", class "img-fluid px-3 px-sm-4 mt-3 mb-4 w-100", src "img/profile8.svg" ]
                        []
                    ]
                ]
            ]
        ]

-- Personal profile page view for user
myProfileView : Model -> Html Msg
myProfileView model = div []
    [ h1 [ class "h3 mb-0 text-gray-800" ]
        [ text "My Profile" ]
    , h3 [ class ("h4 mb-4 " ++ model.msgColor) ]
    [ text model.errorMessage ]
    , case model.editProfile of 
        False -> 
            div [ class "row" ]
                [ div [ class "col-lg-3 mb-5" ]
                    [ div [ class "text-center" ]
                        [ img [ alt "", class "img-fluid px-3 px-sm-4 mt-3 mb-4 w-100", src ("img/" ++ model.homeInfo.imgUrl) ]
                            []
                        ]
                    , a [ class "ml-3 btn btn-success btn-icon-split mb-1", href "#", onClick (GoTo UpdatePicture) ]
                        [ span [ class "icon text-white-50" ]
                            [ i [ class "fas fa-user-edit mt-1 float-left" ]
                                []
                            ]
                        , span [ class "text" ]
                            [ text "Change Profile Picture" ]
                        ]
                    ]
                , div [ class "col-lg-9 mb-4" ]
                    [ div [ class "card shadow mb-4" ]
                        [ div [ class "card-header py-3 mb-0 h-auto" ]
                            [ div [ class "mb-0 d-inline-flex" ]
                                [ h4 [ class "mt-1 font-weight-bold text-primary" ]
                                    [ text (model.homeInfo.firstname ++ " " ++ model.homeInfo.lastname) ]
                                ]
                            , a [ class "mr-2 btn btn-warning btn-icon-split float-right", href "#", onClick EditProfileButtonPressed ]
                                [ span [ class "icon text-white-50" ]
                                    [ i [ class "fas fa-pen mt-1" ]
                                        []
                                    ]
                                , span [ class "text" ]
                                    [ text "Edit" ]
                                ]
                            ]
                        , div [ class "card-body" ]
                            [ div [ class "row" ]
                                [ div [ class "col-4 ml-2" ]
                                    [ p []
                                        [ b []
                                            [ text "Major: " ]
                                        , text model.profileInfo.major
                                        ]
                                    , p []
                                        [ b []
                                            [ text "Minor(s): " ]
                                        , text model.profileInfo.minor
                                        ]
                                    , p []
                                        [ b []
                                            [ text "Year: " ]
                                        , text (String.fromInt model.profileInfo.year)
                                        ]
                                    , p []
                                        [ b []
                                            [ text "GPA: " ]
                                        , text (String.fromFloat model.profileInfo.gpa)
                                        ]
                                    , p []
                                        [ b []
                                            [ text "Favorite Classes: " ]
                                        , br []
                                            []
                                        , text model.profileInfo.favClasses
                                        ]
                                    ]
                                , div [ class "col-7 ml-4" ]
                                    [ p []
                                        [ b []
                                            [ text "Mood: " ]
                                        , text model.profileInfo.mood
                                        ]
                                    , p []
                                        [ b []
                                            [ text "Bio: " ]
                                        , text model.profileInfo.bio
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]

        True ->
            div [ class "row" ]
                [ div [ class "col-lg-3 mb-5" ]
                    [ div [ class "text-center" ]
                        [ img [ alt "", class "img-fluid px-3 px-sm-4 mt-3 mb-4 w-100", src ("img/" ++ model.homeInfo.imgUrl) ]
                            []
                        ]
                    , a [ class "ml-3 btn btn-success btn-icon-split mb-1", href "#" ]
                        [ span [ class "icon text-white-50" ]
                            [ i [ class "fas fa-user-edit mt-1 float-left" ]
                                []
                            ]
                        , span [ class "text" ]
                            [ text "Change Profile Picture" ]
                        ]
                    ]
                , div [ class "col-lg-9 mb-4" ]
                    [ div [ class "card shadow mb-4" ]
                        [ div [ class "card-header py-3 mb-0 h-auto" ]
                            [ div [ class "mb-0 d-inline-flex" ]
                                [ h4 [ class "mt-1 font-weight-bold text-primary" ]
                                    [ text (model.homeInfo.firstname ++ " " ++ model.homeInfo.lastname) ]
                                ]
                            , a [ class "mr-2 btn btn-success btn-icon-split float-right", href "#", onClick SaveProfileButtonPressed ]
                                [ span [ class "icon text-white-50" ]
                                    [ i [ class "fas fa-save mt-1" ]
                                        []
                                    ]
                                , span [ class "text" ]
                                    [ text "Save Changes" ]
                                ]
                            ]
                        , div [ class "card-body" ]
                            [ div [ class "row" ]
                                [ div [ class "col-4 ml-2" ]
                                    [ div [ class "d-inline-flex mb-1" ]
                                        [ b [ class "d-inline-block profile-input-tag" ]
                                            [ text "Major: " ]
                                        , input [ onInput (EditProfileInfo "Major"), attribute "aria-describedby" "basic-addon2", attribute "aria-label" "Search", class "d-inline-block form-control border-0 small", placeholder "Enter a major...", type_ "text", value model.profileInfo.major ]
                                            []
                                        ]
                                    , div [ class "d-inline-flex mb-1" ]
                                        [ b [ class "d-inline-block profile-input-tag" ]
                                            [ text "Minor(s): " ]
                                        , input [ onInput (EditProfileInfo "Minor"), attribute "aria-describedby" "basic-addon2", attribute "aria-label" "Search", class "d-inline-block form-control border-0 small", placeholder "Enter minor(s)...", type_ "text", value model.profileInfo.minor ]
                                            []
                                        ]
                                    , div [ class "d-inline-flex mb-1" ]
                                        [ b [ class "d-inline-block profile-input-tag" ]
                                            [ text "Year:" ]
                                        , input [ onInput (EditProfileInfo "Year"), type_ "number", value (String.fromInt model.profileInfo.year), Html.Attributes.min "1", Html.Attributes.max "4", class "d-inline-block form-control border-0 small"]
                                            []
                                        ]
                                    ,br []
                                        []
                                    ,div [ class "d-inline-flex mb-1" ]
                                        [ b [ class "d-inline-block profile-input-tag" ]
                                            [ text "GPA:" ]
                                        , input [ onInput (EditProfileInfo "GPA"), type_ "number", value (String.fromFloat model.profileInfo.gpa), Html.Attributes.min "0.0", Html.Attributes.max "4.0", step "0.1", class "d-inline-block form-control border-0 small", placeholder "Major"]
                                            []
                                        ]
                                    , div [ class "mb-1 d-inline-block" ]
                                            [ b [ class "d-inline-block profile-input-tag" ]
                                                [ text "Favorite Classes: " ]
                                            , input [ onInput (EditProfileInfo "FavClasses"), attribute "aria-describedby" "basic-addon2", attribute "aria-label" "Search", class "d-inline-block form-control border-0 small", placeholder "Enter favorite classes...", type_ "text", value model.profileInfo.favClasses ]
                                                []
                                            ]
                                    ]
                                ,div [ class "col-7 ml-4" ]
                                        [ div [ class "d-inline-flex mb-1" ]
                                            [ b [ class "d-inline-block profile-input-tag" ]
                                                [ text "Mood: " ]
                                            , input [ onInput (EditProfileInfo "Mood"), attribute "aria-describedby" "basic-addon2", attribute "aria-label" "Search", class "d-inline-block form-control border-0 small", placeholder "Enter mood...", type_ "text", value model.profileInfo.mood ]
                                                []
                                            ]
                                        , br []
                                            []
                                        , div [ class "mb-1 d-inline-block" ]
                                            [ b [ class "d-inline-block profile-input-tag" ]
                                                [ text "Bio: " ]
                                            , br []
                                                []
                                            , textarea [ onInput (EditProfileInfo "Bio"), class "d-inline-block form-control border-0 small", attribute "cols" "60", attribute "maxlength" "500", placeholder "Enter bio...", attribute "rows" "6" ]
                                                [ text model.profileInfo.bio ]
                                            ]
                                        ]
                                ]
                            ]
                        ]
                    ]
                ]
    ]

-- Course search page view from source-findpage.html
findCourseView : Model -> Html Msg
findCourseView model = div []
    [ h1 [ class "h3 mb-0 text-gray-800" ]
        [ text "Find Courses" ]
    , h3 [ class ("h4 mb-4 " ++ model.msgColor) ]
    [ text model.errorMessage ]
    , div [ class "row mb-4" ]
        [ Html.form [ class "col-lg-6 d-none d-sm-inline-block form-inline my-2 my-md-0"]
            [ div [ class "input-group bg-white" ]
                [ input [ onInput SearchForCourse, class "form-control border-0 small", placeholder "Find courses...", type_ "text", value model.searchCoursesQuery ]
                    []
                , div [ class "input-group-append" ]
                    [ button [ class "btn btn-primary", type_ "button" ]
                        [ i [ class "fas fa-search fa-sm" ]
                            []
                        ]
                    ]
                ]
            ]
        , div [ class "col-lg-6" ]
            [ a [ class "btn btn-info btn-icon-split float-left", href "#", onClick (GoTo MyCourses) ]
                [ span [ class "icon text-white-50" ]
                    [ i [ class "fas fa-chalkboard mt-1" ]
                        []
                    ]
                , span [ class "text" ]
                    [ text "Go To My Courses" ]
                ]
            ]
        ]
    , div [ class "row" ]
        (if model.searchCourses == [] then
            [div []
                [ img [ alt "", class "img-fluid p-4 img-center", src "img/undraw_file_searching_duff.svg", attribute "style" "width: 60%;" ]
                    []
                ]]
        else
        ([ div [ class "col-lg-6 h-100" ]
            (List.map 
                (\course -> div [ class "card card-result shadow mb-1", onMouseEnter (HoverOnCourse course), onMouseLeave HoverOffCourse ]
                        [ div [ class "card-header py-3 mb-0 h-auto" ]
                            [ div [ class "mb-0 d-inline-flex" ]
                                [ h6 [ class "font-weight-bold text-info mb-0" ]
                                    [ text course.code
                                    , p [ class "mb-0 text-gray-500 d-block" ]
                                        [ text course.department ]
                                    ]
                                ]
                            , a [ class "mr-2 btn btn-success btn-icon-split float-right", href "#", onClick (AddCourse course.code) ]
                                [ span [ class "icon text-white-50" ]
                                    [ i [ class "fas fa-plus mt-1" ]
                                        []
                                    ]
                                , span [ class "text" ]
                                    [ text "Add" ]
                                ]
                            ]
                        ]
                ) model.searchCourses
            )
        , div [ class "col-lg-6" ]
            (case model.hoverCourse of 
                Just course -> [ div [ class "card shadow border-bottom-info mb-4" ]
                                [ div [ class "card-header py-3 mb-0 mycourse-header" ]
                                    [ div [ class "mb-0 d-inline-flex" ]
                                        [ h6 [ class "font-weight-bold text-info mb-0" ]
                                            [ text course.code
                                            , p [ class "mb-0 text-gray-500" ]
                                                [ text course.department ]
                                            ]
                                        ]
                                    , i [ class "fa fa-info-circle float-right mt-2" ]
                                        []
                                    ]
                                , div [ class "card-body" ]
                                    ((if course.lectures /= [] then
                                        ([ b [] [ text "Lecture Sections: " ] ] ++
                                        ((List.map (\lec -> div [ class "mb-1" ]
                                            [ b [ class "text-info" ]
                                                [ text lec.section ]
                                            , br []
                                                []
                                            , i [ class "fa fa-chalkboard-teacher mr-2" ]
                                                []
                                            , text lec.prof
                                            , br []
                                                []
                                            , i [ class "fa fa-street-view mr-2" ]
                                                []
                                            , text lec.location
                                            , br []
                                                []
                                            , i [ class "fa fa-calendar-week mr-2" ]
                                                []
                                            , text lec.times
                                            ])
                                        ) course.lectures))
                                        else []
                                    ) ++
                                    (if course.tutorials /= [] then
                                        ([ hr [] [], b [] [ text "Tutorial Sections:" ] ] ++
                                        (List.map (\tut -> div [ class "mb-1" ]
                                            [ b [ class "text-info" ]
                                                [ text tut.section ]
                                            , br []
                                                []
                                            , i [ class "fa fa-street-view mr-2" ]
                                                []
                                            , text tut.location
                                            , br []
                                                []
                                            , i [ class "fa fa-calendar-week mr-2" ]
                                                []
                                            , text tut.times
                                            ]
                                        ) course.tutorials))
                                        else []
                                    ) ++
                                    (if course.labs /= [] then
                                        ([ hr [] [], b [] [ text "Lab Sections:" ] ] ++
                                        (List.map (\lab -> div [ class "mb-1" ]
                                            [ b [ class "text-info" ]
                                                [ text lab.section ]
                                            , br []
                                                []
                                            , i [ class "fa fa-street-view mr-2" ]
                                                []
                                            , text lab.location
                                            , br []
                                                []
                                            , i [ class "fa fa-calendar-week mr-2" ]
                                                []
                                            , text lab.times
                                            ]
                                        ) course.labs))
                                        else []
                                    ))
                                ]
                            ]
                Nothing -> []
            )
            --end of card
        ]))
    ]

-- Student Profile search page view from source-findpage.html
findStudentView : Model -> Html Msg
findStudentView model = div []
    [ h1 [ class "h3 mb-0 text-gray-800" ]
        [ text "Find Student" ]
    ,h3 [ class ("h4 mb-4 " ++ model.msgColor) ]
    [ text model.errorMessage ]
    , div [ class "row mb-4" ]
        [ Html.form [ class "col-lg-6 d-none d-sm-inline-block form-inline my-2 my-md-0 navbar-search-classes" ]
            [ div [ class "input-group bg-white" ]
                [ input [ onInput SearchForProfile, class "form-control border-0 small", placeholder "Find students...", type_ "text", value model.searchProfilesQuery ]
                    []
                , div [ class "input-group-append" ]
                    [ button [ class "btn btn-primary", type_ "button" ]
                        [ i [ class "fas fa-search fa-sm" ]
                            []
                        ]
                    ]
                ]
            ]
        , div [ class "col-lg-6" ]
            [ a [ class "btn btn-info btn-icon-split float-left", href "#", onClick (GoTo MyProfile) ]
                [ span [ class "icon text-white-50" ]
                    [ i [ class "fas fa-user mt-1" ]
                        []
                    ]
                , span [ class "text" ]
                    [ text "Go To My Profile" ]
                ]
            ]
        ]
    , div [ class "row" ]
        (if model.searchProfiles == [] then
            [div []
                [ img [ alt "", class "img-fluid p-4 img-center", src "img/undraw_people_search_wctu.svg", attribute "style" "width: 60%;" ]
                    []
                ]]
        else 
        ([ div [ class "col-lg-6 h-100" ]
            (List.map (\student -> div [ class "card card-result shadow mb-1", onMouseEnter (HoverOnProfile student), onMouseLeave HoverOffProfile ]
                 [ div [ class "card-header py-3 mb-0 h-auto" ]
                    [ div [ class "mb-0 d-inline-flex" ]
                        [ h6 [ class "font-weight-bold text-info mb-0" ]
                            [ text student.fullname
                            , p [ class "mb-0 text-gray-500 d-block" ]
                                [ text (student.info.major ++ (
                                    case student.info.year of 
                                        1 -> " I"
                                        2 -> " II"
                                        3 -> " III"
                                        _ -> " IV"
                                )) ]
                            ]
                        ]
                    , a [ class "mr-2 btn btn-info btn-icon-split float-right", href "#", onClick (GoTo (PublicProfile student)) ]
                        [ span [ class "icon text-white-50" ]
                            [ i [ class "fas fa-user mt-1" ]
                                []
                            ]
                        , span [ class "text" ]
                            [ text "View" ]
                        ]
                    , a [ class "mr-2 btn btn-success btn-icon-split float-right", href "#", onClick (Follow student.uname) ]
                        [ span [ class "icon text-white-50" ]
                            [ i [ class "fas fa-user-plus mt-1" ]
                                []
                            ]
                        , span [ class "text" ]
                            [ text "Follow" ]
                        ]
                    ]
                 ]
                    ) model.searchProfiles
                )
        , div [ class "col-lg-6" ]
            ( case model.hoverProfile of 
                Just student -> [ div [ class "card shadow border-bottom-info mb-4" ]
                    [ div [ class "card-header  py-3" ]
                        [ img [ alt "", class "img-fluid  pl-2 pr-3 d-inline-flex", src ("img/" ++ student.imgUrl), attribute "style" "width: 18% !important;" ]
                            []
                        , h4 [ class "m-0 font-weight-bold text-info d-inline-flex" ]
                            [ text student.fullname ]
                        ]
                    , div [ class "card-body" ]
                        [ div [ class "row" ]
                            [ div [ class "col-4 ml-2" ]
                                [ p []
                                    [ b []
                                        [ text "Major: " ]
                                    , text student.info.major
                                    ]
                                , p []
                                    [ b []
                                        [ text "Minor(s): " ]
                                    , text student.info.minor
                                    ]
                                , p []
                                    [ b []
                                        [ text "Year: " ]
                                    , text (String.fromInt (student.info.year))
                                    ]
                                , p []
                                    [ b []
                                        [ text "GPA: " ]
                                    , text (String.fromFloat (student.info.gpa))
                                    ]
                                , p []
                                    [ b []
                                        [ text "Favorite Classes: " ]
                                    , text student.info.favClasses
                                    ]
                                ]
                            , div [ class "col-7 ml-4" ]
                                [ p []
                                    [ b []
                                        [ text "Mood: " ]
                                    , text student.info.mood
                                    ]
                                , p []
                                    [ b []
                                        [ text "Bio: " ]
                                    , text student.info.bio
                                    ]
                                ]
                            ]
                        ]
                    ]
                    ]
                Nothing -> []
            )
        ]))
    ]

-- CourseView page view to show user's courses
myCoursesView : Model -> Html Msg
myCoursesView model = div []
    [ div [ class "d-sm-flex align-items-center justify-content-between mb-4" ]
        [ h1 [ class "h3 mb-0 text-gray-800" ]
            [ text "My Courses" ]
        , h3 [ class ("h4 mb-0 text-center " ++ model.msgColor) ]
        [ text model.errorMessage ]
        , a [ class "d-none d-sm-inline-block btn btn-sm btn-primary shadow-sm", href "#", onClick (GoTo ComingSoon) ]
            [ i [ class "fas fa-share fa-sm text-white-50 mr-2" ]
                []
            , text "Share Classes"
            ]
        ]
    , div [ class "row mb-4" ]
        [ Html.form [ class "col-lg-6 d-none d-sm-inline-block form-inline my-2 my-md-0 navbar-search-classes" ]
            [ div [ class "input-group bg-white" ]
                [ input [ onInput GetUserCourses, attribute "aria-describedby" "basic-addon2", attribute "aria-label" "Search", class "form-control border-0 small", placeholder "Filter courses...", type_ "text" ]
                    []
                , div [ class "input-group-append" ]
                    [ button [ class "btn btn-primary", type_ "button" ]
                        [ i [ class "fas fa-search fa-sm" ]
                            []
                        ]
                    ]
                ]
            ]
        , div [ class "col-lg-6" ]
            [ a [ class "mr-2 btn btn-info btn-icon-split float-left", href "#", onClick (GoTo FindCourse) ]
                [ span [ class "icon text-white-50" ]
                    [ i [ class "fas fa-plus mt-1" ]
                        []
                    ]
                , span [ class "text" ]
                    [ text "Add courses" ]
                ]
            , a [ class "ml-1 btn btn-secondary btn-icon-split float-left", href "#", onClick (GoTo ComingSoon) ]
                [ span [ class "icon text-white-50" ]
                    [ i [ class "fas fa-file-import mt-1" ]
                        []
                    ]
                , span [ class "text" ]
                    [ text "Import classes" ]
                ]
            ]
        ],
        div [class "row" ]
            (if model.courses == [] then
            [div []
                [ img [ alt "", class "img-fluid p-4 img-center", src "img/undraw_exams_g4ow.svg", attribute "style" "width: 60%;" ]
                    []
                ]]
            else
                (List.map2 (\course color ->
                div [ class "col-lg-6" ]
                    [ div [ class ("card shadow mb-4 border-bottom-" ++ color) ]
                        [ div [ class "card-header py-3 mb-0 mycourse-header" ]
                            [ div [ class "mb-0 d-inline-flex" ]
                                [ h6 [ class ("font-weight-bold  mb-0 text-" ++ color) ]
                                    [ text course.code
                                    , p [ class "mb-0 text-gray-500" ]
                                        [ text course.department ]
                                    ]
                                ]
                            , a [ class "mr-2 btn btn-danger btn-icon-split float-right", href "#", onClick (RemoveCourse course.code) ]
                                [ span [ class "icon text-white-50" ]
                                    [ i [ class "fas fa-trash-alt mt-1" ]
                                        []
                                    ]
                                , span [ class "text" ]
                                    [ text "Delete" ]
                                ]
                            ]
                        , div [ class "card-body" ]
                            ((case course.lecture of
                                Just lec -> [
                                    b []
                                        [ text "Lecture Section: " ]
                                        , text lec.section 
                                        , br [] []
                                        , i [ class "fa fa-chalkboard-teacher mr-2" ]
                                            []
                                        , text lec.prof
                                        , br [] []
                                        , i [ class "fa fa-street-view mr-2" ]
                                            []
                                        , text lec.location
                                        , br []
                                            []
                                        , i [ class "fa fa-calendar-week mr-2" ]
                                            []
                                        , text lec.times
                                    ]

                                Nothing -> []    
                            ) ++
                            (case course.tutorial of 
                                Just tut -> [
                                    hr []
                                        []
                                    ,b []
                                        [ text "Tutorial Section: " ]
                                        , text tut.section
                                        , br []
                                            []
                                        , i [ class "fa fa-street-view mr-2" ]
                                            []
                                        , text tut.location
                                        , br []
                                            []
                                        , i [ class "fa fa-calendar-week mr-2" ]
                                            []
                                        , text tut.times
                                        ]

                                Nothing -> []
                            ) ++
                            (case course.lab of 
                                Just lab -> [
                                        hr []
                                            []
                                        , b []
                                            [ text "Lab Section: " ]
                                        , text lab.section
                                        , br []
                                            []
                                        , i [ class "fa fa-street-view mr-2" ]
                                            []
                                        , text lab.location
                                        , br []
                                            []
                                        , i [ class "fa fa-calendar-week mr-2" ]
                                            []
                                        , text lab.times
                                    ]

                                Nothing -> []
                            ))
                        ]
                    ]) model.courses (List.concat (List.repeat (List.length model.courses) colors))))
    ]

-- Base view function with sidebar + topbar
view : Model -> Html Msg
view model = div []
    [ node "link" [ href "vendor/fontawesome-free/css/all.min.css", rel "stylesheet", type_ "text/css" ]
        []
    , node "link" [ href "https://fonts.googleapis.com/css?family=Nunito:200,200i,300,300i,400,400i,600,600i,700,700i,800,800i,900,900i", rel "stylesheet" ]
        []
    , node "link" [ href "css/sb-admin-2.css", rel "stylesheet" ]
        []
    , div [ id "wrapper" ]
        [ ul [ class "navbar-nav bg-gradient-primary sidebar sidebar-dark accordion", id "accordionSidebar" ]
            [ a [ class "sidebar-brand d-flex align-items-center justify-content-center", onClick (GoTo Home), href "#"]
                [ div [ class "sidebar-brand-icon" ]
                    [ i [ class "fas fa-clipboard-check sidebar-brand-text" ]
                        []
                    ]
                , div [ class "sidebar-brand-text mx-2" ]
                    [ text "Course Match" ]
                ]
            , hr [ class "sidebar-divider my-0" ]
                []
            , li [ class "nav-item" ]
                [ a [ class "nav-link home", onClick (GoTo Home), href "#"]
                    [ i [ class "fas fa-fw fa-home" ]
                        []
                    , span []
                        [ text "Home" ]
                    ]
                ]
            , hr [ class "sidebar-divider" ]
                []
            , div [ class "sidebar-heading" ]
                [ text "My Stuff" ]
            , li [ class "nav-item" ]
                [ input [ type_ "checkbox", style "display" "none", id "mycourses" ]
                    []
                , label [ for "mycourses" ]
                    [ a [ class "nav-link collapsed" ]
                        [ i [ class "fas fa-fw fa-calendar" ]
                            []
                        , span []
                            [ text "My Courses" ]
                        ]
                    ]
                , div [ id "courseCollapse", class "collapse" ]
                    [ div [ class "bg-white py-2 collapse-inner rounded" ]
                        [ h6 [ class "collapse-header" ]
                            [ text "Actions:" ]
                        , a [ class "collapse-item", onClick (GoTo MyCourses), href "#" ]
                            [ i [ class "fas fa-chalkboard fa-sm fa-fw mr-2" ]
                                [], text "My courses"
                            ]
                        ]
                    ]
                ]
            , li [ class "nav-item" ]
                [ input [ type_ "checkbox", style "display" "none", id "social" ]
                    []
                , label [ for "social" ]
                    [ a [ class "nav-link collapsed" ]
                        [ i [ class "fas fa-fw fa-user-friends" ]
                            []
                        , span []
                            [ text "Social" ]
                        ]
                    ]
                , div [ id "collapseUtilities", class "collapse" ]
                    [ div [ class "bg-white py-2 collapse-inner rounded" ]
                        [ h6 [ class "collapse-header" ]
                            [ text "My Social:" ]
                        , a [ class "collapse-item", onClick (GoTo MyProfile), href "#" ]
                            [ i [ class "fas fa-user fa-sm fa-fw mr-2" ]
                                [], text "Profile" 
                            ]
                        , a [ class "collapse-item", onClick (GoTo Following), href "#" ]
                            [ i [ class "fas fa-users fa-sm fa-fw mr-2" ]
                                [], text "Following"
                            ]
                        ]
                    ]
                ]
            , hr [ class "sidebar-divider" ]
                []
            , div [ class "sidebar-heading" ]
                [ text "Match" ]
            , li [ class "nav-item" ]
                [ input [ type_ "checkbox", style "display" "none", id "find" ]
                    []
                , label [ for "find" ]
                    [ a [ class "nav-link collapsed" ]
                        [ i [ class "fas fa-fw fa-search" ]
                            []
                        , span []
                            [ text "Find" ]
                        ]
                    ]
                , div [ id "collapsePages", class "collapse" ]
                    [ div [ class "bg-white py-2 collapse-inner rounded" ]
                        [ h6 [ class "collapse-header" ]
                            [ text "Search:" ]
                        , a [ class "collapse-item", onClick (GoTo FindStudent), href "#" ]
                            [ i [ class "fas fa-user-graduate fa-sm fa-fw mr-2" ]
                                [], text "Find student" 
                            ]
                        , a [ class "collapse-item", onClick (GoTo FindCourse), href "#" ]
                            [ i [ class "fas fa-chalkboard-teacher fa-sm fa-fw mr-2" ]
                                [], text "Find course" 
                            ]
                        ]
                    ]
                ]
            , hr [ class "sidebar-divider d-none d-md-block" ]
                []
            , li [ class "nav-item" ]
                [ a [ class "nav-link", onClick Logout, href "#" ]
                    [ i [ class "fas fa-fw fa-sign-out-alt" ]
                        []
                    , span []
                        [ text "Logout" ]
                    ]
                ]
            ]
        , div [ id "content-wrapper", class "d-flex flex-column" ]
            [ div [ id "content" ]
                [ nav [ class "navbar navbar-expand navbar-light bg-white topbar mb-4 static-top shadow" ]
                    [ button [ id "sidebarToggleTop", class "btn btn-link d-md-none rounded-circle mr-3" ]
                        [ i [ class "fa fa-bars" ]
                            []
                        ]
                    , ul [ class "navbar-nav ml-auto" ]
                        [ li [ class "nav-item dropdown no-arrow mx-1" ]
                            [ a [ class "nav-link dropdown-toggle", onClick (GoTo MyCourses), href "#" ]
                                [ i [ class "fas fa-chalkboard-teacher fa-fw" ]
                                    []
                                , span [ class "badge badge-danger badge-counter" ]
                                    [ text (String.fromInt (List.length model.courses)) ]
                                ]
                            ]
                        ,li [ class "nav-item dropdown no-arrow mx-1" ]
                            [ a [ class "nav-link dropdown-toggle", onClick (GoTo Following), href "#" ]
                                [ i [ class "fas fa-users fa-fw" ]
                                    []
                                , span [ class "badge badge-danger badge-counter" ]
                                    [ text (String.fromInt (List.length model.following)) ]
                                ]
                            ]
                        , div [ class "topbar-divider d-none d-sm-block" ]
                            []
                        , li [ class "nav-item dropdown no-arrow" ]
                            [ a [ class "nav-link dropdown-toggle", onClick (GoTo MyProfile), href "#", id "userDropdown" ]
                                [ span [ class "mr-2 d-none d-lg-inline text-gray-600 small" ]
                                    [ text (model.homeInfo.firstname ++ " " ++ model.homeInfo.lastname) ]
                                , img [ class "img-profile rounded-circle", src ("img/" ++ model.homeInfo.imgUrl) ]
                                    []
                                ]
                            ]
                        ]
                    ]
                , div [ class "container-fluid" ]
                    [
                        case model.location of 
                            Home -> homeView model
                            MyCourses -> myCoursesView model
                            MyProfile -> myProfileView model
                            UpdatePicture -> updatePictureView model
                            Following -> followingView model
                            PublicProfile _ -> publicProfileView model
                            FindCourse -> findCourseView model
                            FindStudent -> findStudentView model
                            ComingSoon -> comingSoonView model
                            _ -> div [] []
                    ]
                ]
            , footer [ class "sticky-footer bg-white" ]
                [ div [ class "container my-auto" ]
                    [ div [ class "copyright text-center my-auto" ]
                        [ span []
                            [ text "Copyright", text "©", text "Class Match 2019" ]
                        ]
                    ]
                ]
            ]
        ]
    ]
