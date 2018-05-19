#!/bin/bash
set -e

echo "  ----- clone application repository -----  "
git clone https://github.com/Artemmkin/raddit.git

echo "  ----- install dependent gems -----  "
cd ./raddit
sudo bundle install

echo "  ----- start the application -----  "
sudo systemctl start raddit
sudo systemctl enable raddit
