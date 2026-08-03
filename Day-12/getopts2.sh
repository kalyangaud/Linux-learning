verbose=false

while getopts "v" opt
do 
	case $opt in
		v)
			verbose=true
			;;
	esac
done

echo "Verbose mode : $verbose"

	
