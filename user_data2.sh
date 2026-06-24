#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
echo "<h1>Welcome to Abhishek's Channel | Server 1</h1>" | sudo tee /var/www/html/index.html