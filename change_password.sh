#!/bin/bash

# Change pw in preseeds
sed -i "s|TH3P455W0RD|${1}|g" http/kali-preseed.cfg
sed -i "s|TH3P455W0RD|${1}|g" http/debian-preseed.cfg

# Change in packer files
sed -i "s|TH3P455W0RD|${1}|g" heaven.pkr.hcl
sed -i "s|TH3P455W0RD|${1}|g" heaven-exam.pkr.hcl
sed -i "s|TH3P455W0RD|${1}|g" iotlab.pkr.hcl
sed -i "s|TH3P455W0RD|${1}|g" kali.pkr.hcl
