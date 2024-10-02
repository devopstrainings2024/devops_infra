#!/bin/bash
sudo apt-get update
sudo docker run --name nexus -d -p 8081:8081 sonatype/nexus3
sudo docker run --name sonarqube -d -p 9000:9000 sonarqube
