while getopts "n:a:" opt
do 
	case $opt in
		n) 
			name=$OPTARG
			;;
		a)
			age=$OPTARG
			;;
		*)
			echo "Usage: $0 -n <name> -a <age>"
			exit 1
			;;
	esac
done

echo "Name : $name"
echo "age : $age"
