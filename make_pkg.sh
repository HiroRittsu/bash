#!/bin/sh

cd ./src
catkin_create_rosjava_pkg $1
cd ../
catkin_make

cd ./src/$1/
catkin_create_rosjava_project $2
cd ../../
catkin_make
