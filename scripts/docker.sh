#Step 1: Update Package Index
sudo apt update

#Step 2: Install Dependencies
sudo apt install apt-transport-https ca-certificates curl software-properties-common gnupg

#Step 3: Add Docker’s Official GPG Key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#Step 4: Add Docker Repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

#Step 5: Update Package Index Again
sudo apt update

#Step 6: Install Docker
sudo apt install docker-ce

#Step 7: Start and Enable Docker Service
sudo systemctl start docker
sudo systemctl enable docker

#Step 8: Verify Docker Installation
docker --version
sudo systemctl status docker

#Step 9: Test Docker Installation
sudo docker run hello-world

#Real world Example

#rm -r ./r-markdown-docker

#Make a new directory and navigate to it
mkdir r-markdown-docker
cd r-markdown-docker

#Create a new Dockerfile
#touch Dockerfile
#Adjust it manually
nano Dockerfile

#Create a new R Markdown file
touch your_report.Rmd
#Adjust it manually
nano your_report.Rmd

#Build the Docker image
docker build -t r-markdown-pdf .
docker run --rm -v $(pwd):/workspace r-markdown-pdf 


#Eval Docker
cd eval_report_test
docker build -t eval_report_test .

docker build --no-cache -t eval_report_test .


#Run the Docker container: 
#docker run --rm -v $(pwd):/workspace eval_report_test

docker run -v $(pwd):/workspace eval_report_test





#docker run -v $(pwd)/output:/app eval_report_test

cd eval_report_test


chmod -R 777 eval_report_test


ls

#Enter the Docker container:

cd ..

pwd 
find / -name "0850_results_leh.pdf"

docker run -it --entrypoint /bin/bash eval_report_test

docker exec -it eval_report_test /bin/bash


rm -rf /app/res/0850_2024/*

ls /app/res/0850_2024/

pwd
cd app
cd 0850_2024
cd res
cd 0850_2024
ls

exit

ls -l /app/res/0850_2024/

ls -l /app/res

#Copy to main dir
docker cp a05e520acb9b:/app/res/0850_2024/0850_results_leh.pdf ~/eval_report_test/0850_results_leh.pdf



#Remove all containers
docker container prune

docker volume ls


#Show all containers
docker ps
#Show all active containers
docker ps -a

docker start eval_report_test

docker run -it --name eval_report_test eval_report_test


docker logs eval_report_test

docker images

#Inspect the container
docker inspect --format='{{.State.ExitCode}}' 622abaa24432



#lsof -i :8787
#sudo systemctl stop rstudio-server
#sudo systemctl disable rstudio-server

cd ..

#Enter bin/bash
docker run -it --entrypoint /bin/bash eval_report_test:latest

#Check endpoint
which Rscript

#Is file there?
ls /app/prog/edgar.R

#Run the R script
Rscript /app/prog/edgar.R

docker logs eval_report_test

docker start 9efc69f4b298

docker ps -a




