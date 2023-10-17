SHELL := /bin/bash

# Signifies our desired python version
PY = python3

# .PHONY defines parts of the makefile that are not dependant on any specific file
# This is most often used to store functions
.PHONY = all

# Defining an array variable
FILES =

# Defines the default target that `make` will to try to make, or in the case of a phony target, execute the specified commands
# This target is executed whenever we just type `make`
.DEFAULT_GOAL = all

# App main directory
PROJ_DIR = chatmgr
APP_DIR = $(shell pwd)/${PROJ_DIR}
export APP_DIR

# Setup and launch the app
all: config launch

# The @ makes sure that the command itself isn't echoed in the terminal
help:
	@echo "---------------HELP-----------------"
	@echo "To config the project type make config [prod=on] for production"
	@echo "To test the project type make test"
	@echo "To launch the project type make launch [prod=on] for production"
	@echo "------------------------------------"

# This generates the desired project file structure
config:
ifdef prod # PROD_MODE
	${PY} -m venv venv
	source venv/bin/activate &&	\
	pip install -U pip &&	\
	pip install -r requirements.txt &&	\
	sudo apt-get update &&	\
	sudo apt install nginx &&	\
	sudo rm -rf /etc/nginx/sites-available/default &&	\
	sudo rm -rf /etc/nginx/sites-enabled/default &&	\
	touch /etc/nginx/sites-available/${PROJ_DIR} &&	\
	cp ${PROJ_DIR}/${PROJ_DIR}_nginx.conf /etc/nginx/sites-available/${PROJ_DIR} &&	\
	mkdir -p ${PROJ_DIR}/logs &&	\
	touch ${PROJ_DIR}/logs/nginx-access.log && \
	sudo ln -sf /etc/nginx/sites-available/${PROJ_DIR} /etc/nginx/sites-enabled

else # DEV_MODE
	${PY} -m venv venv
	source venv/bin/activate && \
	pip install -U pip && pip install -r requirements.txt

endif

launch:
ifdef prod # PROD_MODE
	sed -i 's/DEBUG =.*/DEBUG = False/g' ${PROJ_DIR}/${PROJ_DIR}/settings.py
	source venv/bin/activate &&	\
	cd ${PROJ_DIR} &&	\
	python manage.py makemigrations &&	\
	python manage.py migrate &&	\
	python manage.py collectstatic &&	\
	chmod a+x launch_gunicorn.sh &&	\
	./launch_gunicorn.sh $(APP_DIR) && \
	systemctl restart nginx
	@echo "Production server started launchning at: 127.0.0.1:80"

else # DEV_MODE
	@echo $(APP_DIR)
	sed -i 's/DEBUG =.*/DEBUG = True/g' ${PROJ_DIR}/${PROJ_DIR}/settings.py
	source venv/bin/activate &&	\
	cd ${PROJ_DIR} &&	\
	python manage.py makemigrations &&	\
	python manage.py migrate &&	\
	python manage.py runserver 127.0.0.1:8000
	@echo "Development server started running at: 127.0.0.1:8000"

endif

# This function uses pytest to test our source files, not used for now
test:
	${PY} -m pytest

# Cleanup the stuff
clean:
	rm -fr venv 
	rm -f ${PROJ_DIR}/db.sqlite3
	find . -type d -name '__pycache__' -exec rm -rf {} +
