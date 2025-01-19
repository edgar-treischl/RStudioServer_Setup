# Define the IP address as a variable
#ssh root@ip





# Install GitLab

sudo apt update
sudo apt upgrade -y


sudo apt-get install -y curl openssh-server ca-certificates tzdata perl


sudo apt-get install -y postfix
 
#echo "Test email from GitLab server" | mail -s "Test Email" your-email@example.com




curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash

#Add IP
#sudo EXTERNAL_URL="164.92.139.78" apt-get install gitlab-ee

#Get password
sudo cat /etc/gitlab/initial_root_password


#Configure GitLab
sudo nano /etc/gitlab/gitlab.rb

# Enable GitLab Pages (for serving static sites)
sudo gitlab-ctl restart

sudo gitlab-ctl status



#Next GL Runner
curl -LJO "https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/deb/gitlab-runner-helper-images.deb"
curl -LJO "https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/deb/gitlab-runner_amd64.deb"

sudo dpkg -i gitlab-runner-helper-images.deb gitlab-runner_amd64.deb

sudo apt-get install -f


sudo gitlab-runner register



#Install R (if needed)

apt install r-base-core

sudo apt install -y libcurl4-openssl-dev

sudo apt install -y libgit2-dev

sudo apt install -y \
    build-essential \
    libssl-dev \
    libxml2-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    libxt-dev
    
sudo apt-get install -y \
  git \
  make \
  gcc
    
curl https://packages.gitlab.com/gpg.key | sudo apt-key add -

sudo apt-get update
    
R -e "install.packages('pak')"
R -e "pak::pkg_install('pkgdown')"



#sudo nano /etc/gitlab/gitlab.rb

# Enable GitLab Pages (for serving static sites)
#!/bin/bash

# Define the file path for the GitLab configuration file
cp "$GITLAB_CONFIG" "$GITLAB_CONFIG.bak"


pages_external_url "http://164.92.139.78/"
gitlab_pages['enable'] = true
gitlab_pages['listen_proxy'] = "0.0.0.0:8090"
#gitlab_pages['external_http'] = ['http://0.0.0.0:80']






# Reconfigure GitLab to apply the changes
sudo gitlab-ctl reconfigure

sudo gitlab-ctl restart

# Check if true
sudo nano /etc/gitlab/gitlab.rb

grep 'gitlab_pages' /etc/gitlab/gitlab.rb
grep 'pages_external_url' /etc/gitlab/gitlab.rb




#Register GitLab Runner for CI/CD
sudo gitlab-runner register


sudo gitlab-runner run

#Further inspect in case of error
sudo nano /etc/gitlab-runner/config.toml

#Enable and start the GitLab Runner service
sudo systemctl enable gitlab-runner
sudo systemctl start gitlab-runner




# Check the GitLab Runner configuration
cat /etc/gitlab-runner/config.toml

# Search for the builds directory
find /home/gitlab-runner -type d -name "builds"

# Search for the public directory
find /home/gitlab-runner -type d -name "public"

cd /home/gitlab-runner/builds/t3_bzpD3T/0/root/tester/public

ls -l




