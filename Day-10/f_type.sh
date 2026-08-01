echo "Enter the filename"
read file

case $file in
	*.txt)
		echo "Text file"
		;;
	*.sh)
		echo "Shell Script"
		;;
	*.log)
		echo "Log file"
		;;
	*)
		echo "Unknown file"
		;;
esac		
