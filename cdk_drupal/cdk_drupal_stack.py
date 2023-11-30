import os.path
from constructs import Construct
import aws_cdk as cdk
from aws_cdk import (
    # Duration,
    Stack,
    aws_ec2 as ec2,
    aws_s3_assets as s3_assets,
    App
)
with open("./cdk_drupal/configure.sh") as f:
    user_data = f.read()
class EC2InstanceStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        self.instance_ami = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20230919"
        self.instance_type = "t3.micro"
        self.security_group_id = "sg-ec23ca85"
        self.key_name = "cloudops368"
        self.key_type = "rsa"
        self.vpcId = "vpc-57698a3e"
        self.public_subnet_id = "subnet-7d907314"
        self.availability_zone = "ap-northeast-2a"

        cfn_key_pair = ec2.CfnKeyPair(
            self
            , "MyCfnKeyPair"
            , key_name=self.key_name
            , key_type=self.key_type
        )
        vpc = ec2.Vpc.from_lookup(
            self, 
            "vpc",
            vpc_id=self.vpcId,
         )
        security_group = ec2.SecurityGroup.from_lookup_by_id(
            self
            , "security_group"
            , security_group_id=self.security_group_id
        )
        public_subnet = ec2.Subnet.from_subnet_attributes(
            self, "PublicSubnet", subnet_id=self.public_subnet_id, availability_zone=self.availability_zone
        )
        # Instance
        instance = ec2.Instance(self, "Instance"
            ,instance_type=ec2.InstanceType(self.instance_type)
            , machine_image=ec2.MachineImage().lookup(name=self.instance_ami)
            , vpc = vpc
            , security_group = security_group
            , key_name= cfn_key_pair.key_name
            , vpc_subnets=ec2.SubnetSelection(subnets=[public_subnet])
            , user_data=ec2.UserData.custom(user_data)
            )

        # # Script in S3 as Asset
        # asset = s3_assets.Asset(self, "s3_assets", path=os.path.join(dirname, "configure.sh"))
        # local_path = instance.user_data.add_s3_download_command(
        #     bucket=asset.bucket,
        #     bucket_key=asset.s3_object_key
        # )

        # # Userdata executes script from S3
        # instance.user_data.add_execute_file_command(
        #     file_path=local_path
        #     )
        # asset.grant_read(instance.role)




