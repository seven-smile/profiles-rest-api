#!/usr/bin/env bash

set -e

# TODO: Set to URL of git repo.
PROJECT_GIT_URL='https://github.com/seven-smile/profiles-rest-api.git'

PROJECT_BASE_PATH='/usr/local/apps/profiles-rest-api'

# Set Ubuntu Language 
locale-gen en_GB.UTF-8
echo ""

# Install Python, SQLite and pip
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3-dev python3-venv sqlite3 python3-pip supervisor nginx git build-essential libssl-dev gcc uwsgi-plugin-python3 python3-distutils
echo ""

if [ -d "$PROJECT_BASE_PATH" ]; then
    echo "Directory exists"
    echo ""
    sudo rm -rf "$PROJECT_BASE_PATH"
fi

mkdir -p $PROJECT_BASE_PATH
git clone $PROJECT_GIT_URL $PROJECT_BASE_PATH
echo ""

#create virtual environment
mkdir -p $PROJECT_BASE_PATH/env
python3 -m venv $PROJECT_BASE_PATH/env
source $PROJECT_BASE_PATH/env/bin/activate
echo ""

$PROJECT_BASE_PATH/env/bin/pip install -r $PROJECT_BASE_PATH/requirement.txt
# $PROJECT_BASE_PATH/env/bin/pip install uwsgi
$PROJECT_BASE_PATH/env/bin/pip list


# Run migrations
cd $PROJECT_BASE_PATH
pwd
$PROJECT_BASE_PATH/env/bin/python manage.py migrate
$PROJECT_BASE_PATH/env/bin/python manage.py collectstatic --noinput
echo ""

# Setup Supervisor to run our uwsgi process.
cp $PROJECT_BASE_PATH/deploy/supervisor_profiles_api.conf /etc/supervisor/conf.d/profiles_api.conf
supervisorctl reread
supervisorctl update
supervisorctl restart profiles_api
echo ""

# Setup nginx to make our application accessible.
cp $PROJECT_BASE_PATH/deploy/nginx_profiles_api.conf /etc/nginx/sites-available/profiles_api.conf
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/profiles_api.conf /etc/nginx/sites-enabled/profiles_api.conf
systemctl restart nginx.service
echo ""

echo "DONE! :)"
