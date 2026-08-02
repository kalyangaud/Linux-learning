servers=("web1" "web2" "db1" "backup1")

for server in "${servers[@]}"
do 
	echo "Coonecting to $server...."
	ping -C 1 "$server"
done	
