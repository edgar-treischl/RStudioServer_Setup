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
touch Dockerfile
#Adjust it manually
nano Dockerfile

#Create a new R Markdown file
touch your_report.Rmd
#Adjust it manually
nano your_report.Rmd

#Build the Docker image
docker build -t r-markdown-pdf .


#Run the Docker container: 
docker run --rm -v $(pwd):/workspace r-markdown-pdf










