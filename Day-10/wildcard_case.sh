echo "Enter the character "
read ch

case $ch in
	[0-9])
		echo "You entered aa digit"
		;;
	[a-z])
		echo "You entered a lowercase letter"
		;;
	[A-Z])
		echo "You entered the uppercase letter"
		;;
	*)
		echo "Youy entered  a special character or multiple characters."
		;;
esac		
