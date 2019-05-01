from django.db import models
from django.contrib.auth.models import User
from coursematchapp.models import Course, Class

# Manager for Student Model
class StudentManager(models.Manager):
    def create_student(self, username, password, firstname, lastname):
        user = User.objects.create_user(username=username, password=password)
        user.first_name = firstname
        user.last_name = lastname
        user.save()
        studentinfo = self.create(user=user)
        return studentinfo

class Student(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE,
                                    primary_key=True)
    #Information Fields
    major = models.CharField(max_length=60, blank=True)
    minor = models.CharField(max_length=60, blank=True)
    year = models.IntegerField(default=1)
    gpa = models.FloatField(default=1.0)
    fav_classes = models.CharField(max_length=150, blank=True)
    mood = models.CharField(max_length=60, blank=True)
    bio = models.TextField(blank=True)
    profile_url = models.CharField(max_length=50, default='profile1.svg')
    messages = models.IntegerField(default=0)
    courses = models.ManyToManyField(Course)
    classes = models.ManyToManyField(Class)
    following = models.ManyToManyField('self')
    
    def __str__(self):
        return self.user.username

    objects = StudentManager()