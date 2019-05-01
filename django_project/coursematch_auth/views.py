from django.shortcuts import render
from django.http import HttpResponse
from django.contrib.auth.models import User
from django.contrib.auth import authenticate, login, logout
from django.http import JsonResponse
import json
from .models import Student

# Function to log in a user
def login_user(request):
    """
    Recieves a json request { 'username' : val0, 'password' : val1 } and
    authenticates and loggs the user upon sucess
    """
    # Retreive json data from request
    json_req = json.loads(request.body)
    uname = json_req.get('username','')
    passw = json_req.get('password','')
    rememberUser = json_req.get('remeber_user', False)  # Check if the remember me checkbox is checked
    # Authenticate user
    user = authenticate(request, username=uname, password=passw)
    if user is not None:    # If user is authenticated then log them in and set the expiry
        login(request, user)
        request.session['remember_user'] = rememberUser
        request.session.set_expiry(172800)
        return HttpResponse("LoggedIn")
    else:
        return HttpResponse("LoginFailed")

# Return whether a user is authenticated
def get_auth(request):
    '''
    Checks whether a user is authenticated and returns a message accordingly
    '''
    if request.user.is_authenticated:
        return HttpResponse("Authenticated")
    else:
        return HttpResponse("NotAuthenticated")

# Get user information
def get_user_info(request):
    '''
    Retreive all user information about the Student object associated with the logged in user.
    Returns a dictionary with all nessesary information
    '''
    respD = {}      # Create dictionary
    # Get student object 
    student = Student.objects.get(user=request.user)
    # Add information to dict
    respD['firstname'] = request.user.first_name
    respD['lastname'] = request.user.last_name
    nb_following = student.following.all().count()
    respD['following'] = nb_following
    # Check completion percentage
    completion = 20
    if student.major is not '': completion += 16
    if student.minor is not'': completion += 16
    if student.fav_classes is not '': completion += 16
    if student.mood is not '': completion += 16
    if student.bio is not '': completion += 16
    respD['profileCompletion'] = completion
    respD['daysUntilEnd'] = 4
    respD['imgUrl'] = Student.objects.get(user=request.user).profile_url
    # Return the JSON response
    return JsonResponse(respD)

# Register a new user
def register_user(request):
    """
    Recieves a json request containing firstname, lastname, username, password and the confirm password
    and creates a user and loggs them in upon sucess
    """
    # Retreive json data from request
    json_req = json.loads(request.body)
    fname = json_req.get('firstname','')
    lname = json_req.get('lastname','')
    uname = json_req.get('username','')
    passw = json_req.get('password','')
    confirmpassw = json_req.get('confirm','')
    # Error checking in fields
    if fname == '':
        return HttpResponse("First Name cannot be empty")
    elif lname == '':
        return HttpResponse("Last Name cannot be empty")
    elif uname == '':
        return HttpResponse("MacID cannot be empty")
    elif len(passw) < 8:
        return HttpResponse("Password must be at least 8 characters long")
    elif passw != confirmpassw:
        return HttpResponse("Passwords must match")
    else:
        # Create and save the new Student with user information
        newStudent = Student.objects.create_student(username=uname, password=passw, firstname=fname, lastname=lname)
        newStudent.save()
        user = authenticate(request, username=uname, password=passw)
        login(request, user)
        request.session['remember_user'] = False
        return HttpResponse("UserRegistered")

# Logout function
def logout_user(request):
    """
    Loggs out a user based on whether they wanted to be remembered when they logged in
    """
    remembered = request.session.get('remember_user',False)
    if not request.user.is_authenticated:
        return HttpResponse("NotAuthenticated")
    elif remembered:
        return HttpResponse("RedirectOnly")
    else:
        logout(request)
        return HttpResponse("LoggedOut")
    
    