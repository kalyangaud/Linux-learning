<< task
Deploy a Django app
and handle the code for errors
task

code_clone(){
	echo "Cloning the Django app...."
	git clone https://github.com/gaudkalyan/django-notes-app.git
}

install_requirements(){
	echo "Installing dependencies "
	sudo apt-get install docker.io nginx -y
}

required_restart(){
	sudo chown $USER /var/run/docker.sock
	sudo systemctl enable docker
	sudo systemctl enable nginx
	sudo systemctl restart docker

 }

 deploy()
 {
        docker build -t notes-app .
	docker run -d -p 8000:8000 notes-app:latest
}

echo "--------Deployment Started-----------"
if ! code_clone; then
	echo "the code directory already exist"
	cd django-notes-app
fi

if ! install_requirement; then
	echo"Installation failed"
	exit 1
if ! required_restart; then
       echo "the system default error"
       exit 1
fi

if ! deploy; then
	echo "Deployment failed, mailing to admin"
	#sendmail
fi

echo "---------Deployment Successfull------"
