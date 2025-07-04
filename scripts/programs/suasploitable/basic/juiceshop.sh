#!/bin/bash

# Pull and run juiceshop
docker pull bkimminich/juice-shop
docker run -d --restart=always -p 8080:3000 bkimminich/juice-shop