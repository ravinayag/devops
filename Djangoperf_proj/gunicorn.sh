#!/bin/bash

# Name of the application
NAME="Scraper_Project"

# Django project directory & communicte using this unix socket
DJANGODIR=/home/tssdev/TSS-Backend
SOCKFILE=/home/tssdev/TSS-Backend/tssdev_gunicorn.sock

# The user & group to run as
USER=tssdev
GROUP=www-data

# No. of worker processes should Gunicorn spawn
NUM_WORKERS=4

# Which settings file should Django use
DJANGO_SETTINGS_MODULE=scraper_project.settings

# WSGI module name
DJANGO_WSGI_MODULE=scraper_project.wsgi

echo "Starting $NAME as `whoami`"

# Activate the virtual environment
cd $DJANGODIR
source ../tss-venv/bin/activate
export DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS_MODULE
export PYTHONPATH=$DJANGODIR:$PYTHONPATH

# Create the run directory if it doesn't exist
#RUNDIR=$(dirname $SOCKFILE)
#test -d $RUNDIR || mkdir -p $RUNDIR

# Start your Django Gunicorn
# Programs meant to be run under supervisor should not daemonize themselves (do not use --daemon)
exec ../tss-venv/bin/gunicorn ${DJANGO_WSGI_MODULE}:application \
--name $NAME \
--workers $NUM_WORKERS \
--user=$USER --group=$GROUP \
--bind=unix:$SOCKFILE \
--log-level=debug \
--timeout 600 \
--log-file=-

