#!/bin/bash

cd /home/ubuntu/app


sudo su root


export DB_HOST=mongodb://${db_ip}/blog

sleep 5


sudo npm install



sleep 5





pm2 -f start app.js
 



