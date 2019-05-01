from . import views
from django.urls import path

# routed from /e/kostiukb/coursematchapp
urlpatterns = [
    path('getprofileinfo/', views.get_profile_info, name='coursematchapp-get_profile_info'),
    path('saveprofileinfo/', views.save_profile_info, name='coursematchapp-save_profile_info'),
    path('getusercourses/', views.get_user_courses, name='coursematchapp-get_user_courses'),
    path('searchcourses/', views.search_courses, name='coursematchapp-search_courses'),
    path('searchprofiles/', views.search_profiles, name='coursematchapp-search_profiles'),
    path('addcourse/', views.add_course, name='coursematchapp-add_course'),
    path('removecourse/', views.remove_course, name='coursematchapp-remove_course'),
    path('followuser/', views.follow_user, name='coursematchapp-follow_user'),
    path('getfollowing/', views.get_following, name='coursematchapp-get_following'),
    path('unfollowstudent/', views.unfollow_student, name='coursematchapp-unfollow_student'),
    path('unfollowall/', views.unfollow_all, name='coursematchapp-unfollow_all'),
    path('updatepicture/', views.update_picture, name='coursematchapp-update_picture')
]