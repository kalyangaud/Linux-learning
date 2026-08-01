#!/bin/bash 

echo "Choose an option :"
echo "1. Date :"
echo "2. Current Directory :"
echo "3. Logged user is :"
read choice

case $choice in
	1)
		date;;

	2)
		pwd;;
	3)
		whoami;;
	*)
		echo "invalid option"
		;;
esac		
