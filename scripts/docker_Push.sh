docker login

#Find the image
docker images
docker tag c8deceae8af6 ejtreischl/reportmastertest:latest

#Build the container
docker build -t reportmastertest .

#Check if the container was built and runs
docker ps -a
#docker start a05e520acb9b


docker push ejtreischl/reportmastertest:latest

#Save the container
docker images

docker save -o eval_report_test.tar eval_report_test

ls -l eval_report_test.tar


#docker save -o ~/eval_report_test/reportmastertest.tar reportmastertest:latest



