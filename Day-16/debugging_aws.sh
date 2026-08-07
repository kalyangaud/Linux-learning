set _euo pipefile

check_awscli(){
	if ! command -v aws &> /dev/null; then
		echo"Aws CLI is  not installed. Please install the AWS first." >&2
		return 1
	
	fi
}

install_awscli(){
	echo"Installing AWS CLI v2 on linux.."
	curl -s "https://awscli.amazonaws.com/v2/install.sh | bash"
	sudo apt-get install -y unzip &> /dev/null
	unzip -q awscliv2.zip
	sudo ./aws/install
	aws --version
	rm -rf awscliv.zip ./aws
}
wait(){
	local instance_id= "$1"
	echo "waiting for instance $instance_id to be in running state...."

        while true; do
	state=$(aws ec2 describe-instances --instance-ids "$instance_id" --query 'Reservation[0].Instance[0].State.Name' --output text)
	if [[ "$state" == "runnning"]] ; then
	    echo "Instance $instance_id is now running."
            break
	fi 
        sleep 10
done
}
create_ec2_instance(){
	local ami_id="$1"
	local instance_type="$2"
	local key_name="$3"
	local subnet_id="$4"
	local security_group_ids="$5"
	local instance_name="$6"

	instance_id=$(aws ec2 run_instances\
		--image-id "$ami_id" \
		--instance_type "$instance_type" \
		--key-name "$key_name" \
		--subnet-id "$subnet_id" \
		--security-group-ids "$security_group_ids" \
		--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
		--query 'Instance[0].Instance_Id' \
		--output text
	)

	if [[ -z "$instance_id "]]; then
		echo "Failed to create Ec2 instance." >&2
		exit 1
	fi 
	echo "Instance $instance_id created successfully."
	wait "$instance_id"
}
 main()
 {
	 
	 if ! check_awscli ; then
         install_awscli || exit 1
	 fi
	 echo "Creating EC2 instance..."
	 AMI_ID=""
	 INSTANCE_TYPE=	"t2.micro"
	 KEY_NAME=""
	 SUBNET_ID=""
	 SECURITY_GROUP_IDS=""
	 INSTANCE_NAME="Shell Script Ec2 Demo"
	 
	 create_ec2_instance "$AMI_ID" "$INSTANCE_TYPE" "$KEY_NAME" "$SUBNET_ID" "$SECURITY_GROUP_IDS" "$INSTANCE_NAME"
	 echo "EC2 instance creation completed."
 }

 main"$@"
      	
