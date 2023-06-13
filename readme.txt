#step 1
terraform apply -auto-approve

#step 2
Attach this ec2 security group (tf-allow_web) to the efs network security group in correct AZ

#step3
>> ssh into ec2 instance
ssh -i .\<<ec2-keypair.pem>> ec2-user@<<public ip address>>

sudo su 
sudo yum install amazon-efs-utils
mkdir efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport <<<Mount target DNS>>>:/ efs
(go to EFS > Attach > DNS)
cd efs
EFS stored files should be visible now

ref: 
https://stackoverflow.com/questions/66559401/aws-elastic-beanstalk-efs-mount-error-unknown-filesystem-type-efs\
https://docs.aws.amazon.com/efs/latest/ug/wt1-test.html