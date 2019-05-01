from django.db import models

# Create your models here.
class Course(models.Model):
    code = models.CharField(max_length=30, primary_key=True)
    department = models.CharField(max_length=30)


class Class(models.Model):
    course = models.ForeignKey(Course, on_delete=models.CASCADE)
    section = models.CharField(max_length=10)
    prof = models.CharField(max_length=60, blank=True)
    location = models.CharField(max_length=40)
    times = models.CharField(max_length=300, blank=True)

    def __str__(self):
        return "{}-{}".format(self.course.code, self.section)