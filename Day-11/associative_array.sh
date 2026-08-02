declare -A services

services[web]="nginx"
services[databases]="mysql"
services[cache]="redis"

for key in "${!services[@]}"
do 
	echo "$key -> ${services[$key]}"
done
