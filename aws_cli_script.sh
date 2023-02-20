#Assigment 2 script

#VPC Variables
VPC_CIDR="10.0.0.0/16"

#Subnet Variables
EC2_PUBLIC_SUBNET_CIDR="10.0.1.0/24"
RDS_PRIVATE_SUBNET_1_CIDR="10.0.2.0/24"
RDS_PRIVATE_SUBNET_2_CIDR="10.0.3.0/24"


#Regions us-west-2a & us-west-2b
REGION_2A="us-west-2a"
REGION_2B="us-west-2b"



# _____________Start of commands________________

#Creating a new VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region="us-west-2" --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name, Value="assignment2-vpc"}]'| yq '.Vpc.VpcId')
echo "VPC ID $vpc_id"


#Create a public subnet for the ec2 instance
public_subnet_2a=$(
aws ec2 create-subnet \
--vpc-id $vpc_id \
--cidr-block $EC2_PUBLIC_SUBNET_CIDR \
--availability-zone $REGION_2A \
--tag-specifications 'ResourceType=subnet, Tags=[{Key=Name, Value="ec2_public__west_2a"}]' | yq '.Subnet.SubnetId'
)

aws ec2 modify-subnet-attribute --subnet-id $public_subnet_2a --map-public-ip-on-launch



#Create a private subnet for RDS west 2a
private_subnet_2a=$(
aws ec2 create-subnet \
--vpc-id $vpc_id \
--cidr-block $RDS_PRIVATE_SUBNET_1_CIDR \
--availability-zone $REGION_2A \
--tag-specifications 'ResourceType=subnet, Tags=[{Key=Name, Value="rds_private_west_2a"}]' | yq '.Subnet.SubnetId')

#Create a private subnet for RDS west 2b
private_subnet_2b=$(
aws ec2 create-subnet \
--vpc-id $vpc_id \
--cidr-block $RDS_PRIVATE_SUBNET_2_CIDR \
--availability-zone $REGION_2B \
--tag-specifications 'ResourceType=subnet, Tags=[{Key=Name, Value="rds_private_west_2b"}]' | yq '.Subnet.SubnetId')


echo "Subnet ID $public_subnet_2a"
echo "Subnet ID $private_subnet_2a"
echo "Subnet ID $private_subnet_2b"


#Create Internet Gateway
igw_id=$(
aws ec2 create-internet-gateway \
--tag-specifications 'ResourceType=internet-gateway, Tags=[{Key=Name, Value="a2-igw"}]' | yq '.InternetGateway.InternetGatewayId')
aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id


echo "Internet Gateway $igw_id"
