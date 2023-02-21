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


#Create Route Table
route_table_id=$(
aws ec2 create-route-table \
--vpc-id $vpc_id \
--tag-specifications 'ResourceType=route-table, Tags=[{Key=Name, Value="route-table-as2"}]' | yq '.RouteTable.RouteTableId')

echo "Route Table $route_table_id"

#Add Internet Gateway as a route in RouteTable
aws ec2 create-route \
	--route-table-id $route_table_id \
	--destination-cidr-block 0.0.0.0/0 \
	--gateway-id $igw_id

echo "Added route to Route table $route_table_id"


#Add route table to public ec2 subnet
aws ec2 associate-route-table --subnet-id $public_subnet_2a --route-table-id $route_table_id


#Create Security Groups

#Creating security group for ec2 instance
ec2_sg=$(aws ec2 create-security-group \
	--group-name "ec2-sg" \
	--description "Security Group for ec2 instance" \
	--vpc-id $vpc_id | yq -r '.GroupId')

echo "Security Group For Ec2 instance has been Created $ec2_sg"


#Allowing SSH and HTTP traffic to ec2 instance security group
aws ec2 authorize-security-group-ingress \
	--group-id $ec2_sg \
	--protocol tcp \
	--port 22 \
	--cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
	--group-id $ec2_sg \
	--protocol tcp \
	--port 80 \
	--cidr 0.0.0.0/0

echo "Authorized security group to allow SSH and HTTP traffic"

#Creating security group for database

db_sg=$(aws ec2 create-security-group \
        --group-name "database-sg" \
        --description "Security Group for database" \
        --vpc-id $vpc_id | yq -r '.GroupId')

echo "Security Group For database has been Created $db_sg"

aws ec2 authorize-security-group-ingress \
	--group-id $db_sg \
	--protocol tcp \
	--port 3306 \
	--cidr 0.0.0.0/16

echo "Authorized security group to allow mysql from within my vpc"


#Creating Ec2 instance Ubuntu 22.04
REGION_ec2="us-west-2"
AMI_ID="ami-0735c191cf914754d"
INSTANCE_TYPE="t2.micro"
KEY_NAME="rds-ec2-key"
INSTANCE_NAME="a2-instance"
USER_NAME="ubuntu"
PUBLIC_IP=""

# Create SSH key pair
#aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
#sudo chmod 400 $KEY_NAME.pem


#creating instance
instance=$(aws ec2 run-instances \
    	--image-id $AMI_ID \
    	--instance-type $INSTANCE_TYPE \
    	--key-name $KEY_NAME \
    	--subnet-id $public_subnet_2a \
    	--security-group-ids $ec2_sg \
    	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$INSTANCE_NAME'}]' \
	--query 'Instances[0].InstanceId' --output text)


echo "______________________________________________________"
echo "Instance Created with ID: $instance"


#Command to wait for instance to start running and then proceed to the next command
echo "Waiting for instance to start running..."
aws ec2 wait instance-running --instance-ids $instance


#find the public ip of the instance so we can then ssh into the instance
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $instance --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo "Public IP address of instance: $PUBLIC_IP"


#SSH into instance
#echo "SSH into instance..."
#ssh -i "$KEY_NAME.pem" $USER_NAME@$PUBLIC_IP




#Creating Subnet Group for Database
SUBNET_GROUP_NAME="rds-sng"
rds_subnet_group=$(aws rds create-db-subnet-group \
	--db-subnet-group-name $SUBNET_GROUP_NAME \
	--db-subnet-group-description "Subnet group for rds" \
	--subnet-ids $private_subnet_2a $private_subnet_2b \
	--tags Key=Name,Value=$SUBNET_GROUP_NAME)


echo "Subnet Group for Database has been created $rds_subnet_group"







DB_NAME="mydatabase"
DB_INSTANCE_IDENTIFIER="mydbinstance"
DB_INSTANCE_CLASS="db.t3.micro"
DB_ENGINE="mysql"
DB_ENGINE_VERSION="8.0.28"
DB_MASTER_USERNAME="myusername"
DB_MASTER_PASSWORD="mypassword"
DB_SUBNET_GROUP_NAME="rds-sng"
DB_ALLOCATED_STORAGE=10

aws rds create-db-instance \
    --db-name $DB_NAME \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --db-instance-class $DB_INSTANCE_CLASS \
    --engine $DB_ENGINE \
    --engine-version $DB_ENGINE_VERSION \
    --master-username $DB_MASTER_USERNAME \
    --master-user-password $DB_MASTER_PASSWORD \
    --allocated-storage $DB_ALLOCATED_STORAGE \
    --db-subnet-group-name $DB_SUBNET_GROUP_NAME 













