mapfile -t names < names.txt

for name in "${names[@]}"
do 
	echo "Hello, $name"
done	
