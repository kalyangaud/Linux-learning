## Multicase statement

echo "Enter yes or no :"
read answer

case $answer in
	y|Y|yes|YES|Yes)
		echo "You selected YES"
		;;
	n|N|no|NO|No)
	 	echo "You selectd NO"
		;;
	*)
                echo "Please enter the yes or no"
		;;
esac		
