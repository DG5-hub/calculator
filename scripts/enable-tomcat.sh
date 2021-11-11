#!/bin/bash
 
# Reload daemon
echo "Reload daemon"
sudo systemctl daemon-reload
sudo systemctl start tomcat
# sudo ufw allow 8080
sudo systemctl enable tomcat
 
echo "Done."
