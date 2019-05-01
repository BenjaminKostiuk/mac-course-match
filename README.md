# Project 03 : Course Match
The third project of the CS1XA3 course. 

This project contains the complete source code for CourseMatch: McMaster's first CourseMatching online portal where students can view and match what courses their friends are taking.

## Getting Started

### Setup
* From your desired directory clone the repository with
    ~~~
    git clone https://github.com/BenjaminKostiuk/CS1XA3.git
    ~~~
* Download python 3 if you haven't already from [here](https://www.python.org/downloads/).
* Create a __python virtual environment__ with ```python -m venv ./python_env```
* Activate the environment with ```source python_env/bin/activate```
* Install the required packages to your environment with
    ~~~
    pip install -r CS1XA3/Project03/requirements.txt
    ~~~
* Navigate to the django folder with ```cd CS1XA3/Project03/django_project/```
* Collect the static files needed to run the server with
    ~~~
    python manage.py collectstatic
    ~~~
* Run the django server with
    ~~~
    python manage.py runserver localhost:10031
    ~~~
* Navigate to <https://mac1xa3.ca/e/kostiukb/coursematch/static/index.html>
* Login or Create a new account and start using Course Match!

__Note__: To terminate the server simply press ```Ctrl-C```

__Note__: You can deactivate the python environment at any time with the ```deactivate``` command, __however__ you cannot run the project without it activated.

### Updating the code
All code pertaining to the front-end (html, js, elm) of the web app can be found in the ```elm-pages``` directory.<br/>
All backend code related to django can be found in the ```django_project``` directory.<br/>
All static code used by django can be found in ```elm-pages/static-files/```.

#### In order to update files served by django:
* Place any static files or resources (html, js, img, css etc.) in ```elm-pages/static-files/```
* Navigate to the django project directory with ```cd CS1XA3/Project03/django_project/```
* Collect all static files with
    ~~~
    python manage.py collectstatic
    ~~~
* Run the server again with ```python manage.py runserver localhost:10031```

## Features

### User Features
Course Match offers class matching services as McMaster's first free online platform for comparing schedules & courses. 

Using Course Match's online portal you can:
* __View__ and __Organize__ courses
* __Add__ new courses to your profile
* __Create__ and __Edit__ a unique profile with beautiful avatars to choose from
* __Follow__ other students for easy access
* __Search__ for courses and easily add them to your profile
* __Search__ for friends and classmates and checkout their courses to compare

#### Coming Soon
* __Import__ your courses from McMaster's MyTimetable
* __Easily__ share your courses through social media

### Developer Features

#### Frontend (Elm):
* Use of Html.Events such as onClick, onMouseOn, onMouseOff
* Use of Elm packages such as List, Html, Html.Events, Html.Attributes
* Use of additional files such as css to add visual flair and style
* Use of Elm Package Json.Decode and Json.Encode to send and receive encoded JSON to the django backend

#### Backend (Django):
* Composed of two apps ```coursematch_auth``` for authentication relation requests & ```coursematchapp``` for course and class related requests
* Variety of Models including Student, Course, Class and Django's built-in [User](https://docs.djangoproject.com/en/2.2/ref/contrib/auth/)
* Implements Django sessions and built-in user authentication for login and sign-up
* Use of Model manager for Student Table
* Use of OneToOne Relations for Student to User relationship
* Use of ForeignKey Relationship to attach Class to Course
* Use of ManyToMany Relationship with other Student objects for following field
* Use of JSON get and post requests to retrieve and communicate data with the elm frontend

## Resources

### Templates
CourseMatch's home, login and sign up pages are modeled using [Bootstrap's Free SB Admin 2 Template](https://startbootstrap.com/themes/sb-admin-2/). Also included the sourced _css_ as well as _fonts_ and _icons_ from <https://fontawesome.com/>.

CourseMatch's landing page is modeled using [the Free Appton Template](https://demo.bootstrapious.com/appton/1-1/). Inlcuded are Appton's _fonts_ and _css_.

### Images
Beautiful SVG illustrations hand-picked from [Undraw.co](https://undraw.co/illustrations).<br/>
Profile Avatars sourced from [Flaticon's free icon packs](https://www.flaticon.com/)

### Other
Most of the elm view functions are converted from html using [this](https://mbylstra.github.io/html-to-elm/) Html to Elm converter. The data is then formatted and inputted using Elm functionality.

## Testing

For testing purposes the database comes with sample data:
### Courses and Classes
* MATH 1ZB3
* MATH 1ZC3
* COMPSCI 1XA3
* ECON 1BB3

### Student Accounts
* Alan Turing<br/>
MacID : turinga<br/>
Password : turingpassword

* David Parnas<br/>
MacID : davidp<br/>
Password : parnaspassword

## Built With
* Django
* Elm
* Html
* Css

## Authors 
Benjamin Kostiuk