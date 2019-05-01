from django.shortcuts import render
from django.http import HttpResponse
from django.contrib.auth.models import User
from django.http import JsonResponse
import json
from django.db.models import Q
from coursematch_auth.models import Student
from coursematchapp.models import Course, Class

# Get a users profile data from their Student model
def get_profile_info(request):
    '''
    Returns a dictionary with the students information from their Student model
    '''
    respD = {}
    student = Student.objects.get(user=request.user)
    respD['major'] = student.major
    respD['minor'] = student.minor
    respD['year'] = student.year
    respD['gpa'] = student.gpa
    respD['favClasses'] = student.fav_classes
    respD['mood'] = student.mood
    respD['bio'] = student.bio
    return JsonResponse(respD)

# Get a list of courses for a given user
def get_courses(student, query):
    '''
    Return a list of courses for a given user where the course code or departement name contains
    the query string passed as an arguement.
    '''

    courses = []
    for course in student.courses.filter(Q(code__icontains=query) | Q(department__icontains=query)):
        courseD = {}    # Create a course object to hold information and classes
        courseD['code'] = course.code
        courseD['department'] = course.department
        # If student has any lectures in that course
        try:
            course_lec = student.classes.get(course_id=course.code, section__contains="C")
        except:
            course_lec = None
        if course_lec is not None:
            courseD['lecture'] = {
                'section': course_lec.section,
                'prof': course_lec.prof,
                'location': course_lec.location,
                'times': course_lec.times
            }
        else:
            courseD['lecture'] = None
        # If student has any tutorials in that course
        try:
            course_tut = student.classes.get(course_id=course.code, section__contains="T")
        except:
            course_tut = None
        if course_tut is not None:
            courseD['tutorial'] = {
                'section': course_tut.section,
                'prof': course_tut.prof,
                'location': course_tut.location,
                'times': course_tut.times
            }
        else:
            courseD['tutorial'] = None
        # If student has any labs in that course
        try:
            course_lab = student.classes.get(course_id=course.code, section__contains="L")
        except:
            course_lab = None
        if course_lab is not None:
            courseD['lab'] = {
                'section': course_lab.section,
                'prof': course_lab.prof,
                'location': course_lab.location,
                'times' : course_lab.times
            }
        else:
            courseD['lab'] = None
        courses.append(courseD) # Add the course to the list
    return courses

# Save a user's changed profile information
def save_profile_info(request):
    '''
    Given a JSON object containing
    {
        major: String, minor : String, 
        year : Int, gpa: Float, 
        favclasses: String, mood : String, bio : String
    }
    Update the corresponding fields in the Student model
    '''
    # Get data fields from JSON request
    json_req = json.loads(request.body)
    major = json_req.get('major', '')
    minor = json_req.get('minor', '')
    year = json_req.get('year', 1)
    gpa = json_req.get('gpa', 1.0)
    favclasses = json_req.get('favclasses', '')
    mood = json_req.get('mood', '')
    bio = json_req.get('bio', '')

    # Check for any errors in the fields
    if not request.user.is_authenticated:
        return HttpResponse("NotAuthenticated")
    elif len(major) > 60:
        return HttpResponse("Major must be less than 60 characters")
    elif len(minor) > 60:
        return HttpResponse("Minor(s) must be less than 60 characters")
    elif year > 4 or year < 1:
        return HttpResponse("Year must between 1 and 4")
    elif gpa < 0 or gpa > 4:
        return HttpResponse("GPA must be between 0.0 and 4.0")
    elif len(favclasses) > 150:
        return HttpResponse("Favorite classes must be less than 150 characters")
    elif len(mood) > 60:
        return HttpResponse("Mood must be less than 60 characters")
    else:
        # Change corresponding fields from Student model
        student = Student.objects.get(user=request.user)
        student.major = major
        student.minor = minor
        student.year = year
        student.gpa = gpa
        student.fav_classes = favclasses
        student.mood = mood
        student.bio = bio
        # Save Student
        student.save()
        return HttpResponse("Profile Updated")

def get_user_courses(request):
    respD = {}
    student = Student.objects.get(user=request.user)
    query = request.POST.get('code','') # Used when filtering course request

    respD['courses'] = get_courses(student, query)

    return JsonResponse(respD)
        
def search_courses(request):
    query = request.GET.get('code','')
    respD = {}
    respD['data'] = []
    for course in Course.objects.filter(Q(code__icontains=query) | Q(department__icontains=query)):
        courseD = {}
        courseD['code'] = course.code
        courseD['department'] = course.department
        # Get all lectures
        courseD['lectures'] = []
        for lec in Class.objects.filter(course_id=course.code, section__contains="C"):
            lecD = {
                'section': lec.section,
                'prof': lec.prof,
                'location': lec.location,
                'times': lec.times
            }
            courseD['lectures'].append(lecD)
        courseD['lectures'].sort(key=lambda x: int(x['section'][-1]))
        # Get all tutorials
        courseD['tutorials'] = []
        for tut in Class.objects.filter(course_id=course.code, section__contains="T"):
            tutD = {
                'section': tut.section,
                'prof': tut.prof,
                'location': tut.location,
                'times': tut.times
            }
            courseD['tutorials'].append(tutD)
        courseD['tutorials'].sort(key=lambda x: int(x['section'][-1]))
        # Get all labs
        courseD['labs'] = []
        for lab in Class.objects.filter(course_id=course.code, section__contains="L"):
            labD = {
                'section': lab.section,
                'prof': lab.prof,
                'location': lab.location,
                'times': lab.times
            }
            courseD['labs'].append(labD)
        courseD['labs'].sort(key=lambda x: int(x['section'][-1]))
        respD['data'].append(courseD)
    return JsonResponse(respD)

# Search Student profiles 
def search_profiles(request):
    '''
    Given a query string return a list of Student objects
    to be rendered in the search Student section
    '''
    query = request.GET.get('query','')
    respD = {}
    respD['data'] = []
    # Go through all Students with first_name, last_name or major matching query string
    for student in Student.objects.filter(Q(user__first_name__icontains=query) | 
                                        Q(user__last_name__icontains=query) |
                                        Q(major__icontains=query)):
        studentD = {}
        studentD['uname'] =  student.user.get_username()
        fullname = student.user.get_full_name()
        studentD['fullname'] = fullname
        studentD['imgUrl'] = student.profile_url
        studentD['info'] = {
            'major': student.major,
            'minor': student.minor,
            'year': student.year,
            'gpa': student.gpa,
            'favClasses': student.fav_classes,
            'mood': student.mood,
            'bio': student.bio
        }
        studentD['courses'] = get_courses(student, '')

        respD['data'].append(studentD)
    return JsonResponse(respD)
        
# Update the Student's profile avatar
def update_picture(request):
    '''
    Given the new avatar's url update the user's profile image
    '''
    newImgUrl = request.GET.get('url','')
    if not newImgUrl == '':
        student = Student.objects.get(user=request.user)
        student.profile_url = newImgUrl
        student.save()
        return HttpResponse("Profile Picture Updated")
    else:
        return HttpResponse("Failed To Update Picture")

# Add a course to the Student's model
def add_course(request):
    '''
    Given a unique identifier code for a course, add that course to the
    Student object's courses relationship
    '''
    # Get code
    course_code = request.POST.get('code','')
    
    if not course_code == '':
        # Get Student and Course objects
        student = Student.objects.get(user=request.user)
        newCourse = Course.objects.get(code=course_code)
        # Check if already enrolled
        course_exist_count = student.courses.filter(code=course_code).count()
        if course_exist_count > 0:
            return HttpResponse("You are already enrolled in this course")
        else:
            # Add the course with default lecture
            student.courses.add(newCourse)
            try:
                default_lec = Class.objects.get(course_id=course_code, section='CO1')
            except:
                default_lec = None

            if default_lec is not None:
                student.classes.add(default_lec)
            # Add the course with default tutorial
            try:
                default_tut = Class.objects.get(course_id=course_code, section='TO1')
            except:
                default_tut = None
            
            if default_tut is not None:
                student.classes.add(default_tut)
            # Add the course with default lab
            try:
                default_lab = Class.objects.get(course_id=course_code, section='LO1')
            except:
                default_lab = None

            if default_lab is not None:
                student.classes.add(default_lab)
            
            student.save()
            return HttpResponse("Course Added")
    else:
        return HttpResponse("Failed To Add Course")

# Remove course from Student's courses field
def remove_course(request):
    '''
    Given a course's unique identifier code, remove it from the student's course field
    '''
    # Get course code
    course_code = request.POST.get('code','')

    if not course_code == '':
        student = Student.objects.get(user=request.user)
        course_to_remove = Course.objects.get(code=course_code)
        # Remove the course relationship from the student
        student.courses.remove(course_to_remove)
        # Remove all related classes, (lectures, tutorials, labs)
        for enrolled_class in student.classes.filter(course_id=course_code):
            student.classes.remove(enrolled_class)
        return HttpResponse("Course Removed")
    else:
        HttpResponse("Failed to Remove Course")

# Follow a user from their username
def follow_user(request):
    '''
    Given a unique username for a Student, follow that student and add
    them to the user's Student.following field
    '''
    uname = request.POST.get('username','')
    
    if not uname == '':
        student = Student.objects.get(user=request.user)
        student_to_follow = Student.objects.get(user__username=uname)
        student.following.add(student_to_follow)
        student.save()
        return HttpResponse("Followed Student")
    else:
        return HttpResponse("Failed to Follow Student")

# Get a list of all student's the user is following
def get_following(request):
    '''
    Given a query filter the student's the user is following
    and return a list of their profiles
    '''
    # Get query and student objects
    query = request.POST.get('query','')
    student = Student.objects.get(user=request.user)
    # Create a return dict
    respD = {}
    respD['data'] = []
    # Create a list of profiles of the students the user is following
    for follow in student.following.filter(Q(user__first_name__icontains=query) | Q(user__last_name__icontains=query) | Q(major__icontains=query)):
        studentD = {}
        studentD['uname'] = follow.user.get_username()
        fullname = follow.user.get_full_name()
        studentD['fullname'] = fullname
        studentD['imgUrl'] = follow.profile_url
        studentD['info'] = {
            'major': follow.major,
            'minor': follow.minor,
            'year': follow.year,
            'gpa': follow.gpa,
            'favClasses': follow.fav_classes,
            'mood': follow.mood,
            'bio': follow.bio
        }
        studentD['courses'] = get_courses(student, '')
        
        respD['data'].append(studentD)
    return JsonResponse(respD)

# Unfollow a student by their username
def unfollow_student(request):
    # Get username
    uname = request.POST.get('username','')

    if not uname == '':
        # Find student object assosicated with user
        student = Student.objects.get(user=request.user)
        unfollowed_student = Student.objects.get(user__username=uname)
        # remove student from following relationship
        student.following.remove(unfollowed_student)
        student.save()
        return HttpResponse("Unfollowed Student")
    else:
        return HttpResponse("Failed to unfollow Student")

# Unfollow all students
def unfollow_all(request):
    '''
    Removes all student objects from the following many-to-many relationship of the user
    '''
    student = Student.objects.get(user=request.user)
    student.following.clear()
    student.save()
    return HttpResponse("Unfollowed All")