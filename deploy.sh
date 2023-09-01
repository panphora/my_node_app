#!/bin/bash

# Variables
DROPLET_IP=161.35.10.230
USER=hyperspace
DOMAIN=go.panphora.com
GIT_REPO=https://github.com/panphora/my_node_app.git
APP_DIR=~/www/my_node_app

# SSH into the server
ssh $USER@$DROPLET_IP << ENDSSH
  
  # Update and install packages
  # sudo apt-get update
  # sudo apt-get install -y nginx git
  
  # Check if Nginx config already exists, if not create one
  if [ ! -f /etc/nginx/sites-available/my_node_app ]; then
    sudo tee /etc/nginx/sites-available/my_node_app <<EOL
    server {
      listen 80;
      server_name $DOMAIN www.$DOMAIN;
      location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
      }
    }
EOL
    sudo ln -s /etc/nginx/sites-available/my_node_app /etc/nginx/sites-enabled
  fi
  
  # Restart Nginx
  sudo nginx -s reload
  
  # Check if SSL is already set up, if not set up SSL
  if [ ! -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ]; then
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository ppa:certbot/certbot -y
    sudo apt-get update
    sudo apt-get install -y certbot
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN
  fi
  
  # Clone the repository or pull the latest changes
  if [ -d "$APP_DIR" ]; then
    cd $APP_DIR
    git pull origin master
  else
    git clone $GIT_REPO $APP_DIR
    cd $APP_DIR
  fi
  
  # Install Node.js dependencies
  npm install
  
  # Install PM2 if not installed
  if ! [ -x "$(command -v pm2)" ]; then
    npm install -g pm2
  fi
  
  # Start or restart the app using PM2
  pm2 delete my_node_app || true
  pm2 start app.js --name my_node_app

ENDSSH