names=()

while read -r line
do
	names+=("$line")
done < names.txt

for name in "${names[@]}"
do 
	echo "$name"
done
