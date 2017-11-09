#!/bin/bash

cd /home/ubuntu/app

export DB_HOST=mongodb://${db_ip}/blog

sleep 2


npm install && pm2 -f start app.js
 



