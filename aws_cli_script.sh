#Assigment 2 script

#VPC Variables
VPC_CIDR="10.0.0.0/16"

#Subnet Variables
EC2_PUBLIC_SUBNET_CIDR="10.0.1.0/24"
RDS_PRIVATE_SUBNET_1_CIDR="10.0.2.0/24"
RDS_PRIVATE_SUBNET_2_CIDR="10.0.3.0/24"


#Regions us-west-2a & us-west-2b
REGION_2A="us-west-2a"
REGION_2b="us-west-2b"



# _____________Start of commands________________

#Creating a new VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region="us-west-2" --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name, Value="assignment2-vpc"}]'| yq '.Vpc.VpcId')
echo "VPC ID $vpc_id"


#Create a public subnet for the ec2 instance
public_subnet=$(
aws ec2 create-subnet \
--vpc-id $vpc_id \
--cidr-block $EC2_PUBLIC_SUBNET_CIDR \
--availability-zone $REGION_2A \
--tag-specifications 'ResourceType=subnet, Tags=[{Key=Name, Value="ec2_public_subnet"}]' | yq '.Subnet.SubnetId'
)
echo "Subnet ID $public_subnet"

