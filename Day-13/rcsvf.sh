while IFS="," read name age roll_no
do 
	echo " The name is : $name"
	echo "The age is : $age"
	echo "The roll no is $roll_no"

done < test.csv
