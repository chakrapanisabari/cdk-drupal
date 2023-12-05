from aws_cdk import aws_rds as rds, aws_ec2 as ec2, RemovalPolicy as remove
from aws_cdk import Stack, CfnOutput
from constructs import Construct

class RDSInstanceStack(Stack):

    def __init__(self, scope: Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)
        
        self.vpcId = "vpc-57698a3e"
        vpc = ec2.Vpc.from_lookup(
            self, 
            "vpc",
            vpc_id=self.vpcId,
         )
        # Create a MySQL RDS instance
        myDB = rds.DatabaseInstance(self, 
                "MyDatabase",
                engine= rds.DatabaseInstanceEngine.MYSQL,
                vpc= vpc,
                vpc_subnets= ec2.SubnetSelection(
                    subnet_type= ec2.SubnetType.PUBLIC,
                ),
                credentials= rds.Credentials.from_generated_secret("Admin"),
                instance_type= ec2.InstanceType.of(ec2.InstanceClass.BURSTABLE3,
                                                    ec2.InstanceSize.MICRO),
                port= 3306,
                allocated_storage= 80,
                multi_az= False,
                removal_policy= remove.DESTROY,
                deletion_protection= False,
                publicly_accessible= True
                )
        
        myDB.connections.allow_from_any_ipv4(
                ec2.Port.tcp(3306),
                description= "Open port for connection"
            )
            
        CfnOutput(self, 
                    "db_endpoint",
                    value= myDB.db_instance_endpoint_address)

