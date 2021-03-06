# Generated by Django 2.1.7 on 2019-04-21 20:56

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('coursematch_auth', '0001_initial'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='student',
            name='info',
        ),
        migrations.AddField(
            model_name='student',
            name='bio',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='student',
            name='fav_classes',
            field=models.CharField(blank=True, max_length=150),
        ),
        migrations.AddField(
            model_name='student',
            name='gpa',
            field=models.FloatField(default=1.0),
        ),
        migrations.AddField(
            model_name='student',
            name='major',
            field=models.CharField(blank=True, max_length=60),
        ),
        migrations.AddField(
            model_name='student',
            name='messages',
            field=models.IntegerField(default=0),
        ),
        migrations.AddField(
            model_name='student',
            name='minor',
            field=models.CharField(blank=True, max_length=60),
        ),
        migrations.AddField(
            model_name='student',
            name='mood',
            field=models.CharField(blank=True, max_length=60),
        ),
        migrations.AddField(
            model_name='student',
            name='year',
            field=models.IntegerField(default=1),
        ),
    ]
