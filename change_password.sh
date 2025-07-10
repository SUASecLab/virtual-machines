#!/bin/bash

# Change pw in preseeds
sed -i "s|TH3P455W0RD|${1}|g" http/kali-preseed.cfg
sed -i "s|TH3P455W0RD|${1}|g" http/debian-preseed.cfg

PASSWORD=$(openssl rand -base64 10)

# Change in packer files
sed -i "s|TH3P455W0RD|${1}|g" heaven.pkr.hcl
sed -i "s|TH3P455W0RD|${1}|g" heaven-exam.pkr.hcl
sed -i "s|TH3P455W0RD|${1}|g" iotlab.pkr.hcl
sed -i "s|TH3P455W0RD|${1}|g" kali.pkr.hcl
sed -i "s|TH3P455W0RD|${1}|g" http/debian-preseed.cfg

sed -i "s|TH3P455W0RD|${PASSWORD}|g" http/suasploitable-basic-preseed.cfg
sed -i "s|TH3P455W0RD|${PASSWORD}|g" suasploitable-cloud.pkr.hcl
sed -i "s|TH3P455W0RD|${PASSWORD}|g" suasploitable-devbox.pkr.hcl
