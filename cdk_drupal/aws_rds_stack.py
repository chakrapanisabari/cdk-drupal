from aws_cdk import aws_rds as rds
from aws_cdk import Stack
from constructs import Construct

class RDSInstanceStack(Stack):

    def __init__(self, scope: Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        # Create a MySQL RDS instance
        db_instance = rds.DatabaseInstance(
            self,
            "MyDatabase",
            engine=rds.DatabaseInstanceEngine.mysql(
                version=rds.MysqlEngineVersion.VER_8_0
            ),
            instance_class=Stack.Fn.select(0, ["db.t2.micro"]),
            vpc_subnet_type=rds.SubnetType.ISOLATED,  # Change to rds.SubnetType.PRIVATE if needed
            removal_policy=Stack.RemovalPolicy.DESTROY,  # Change as needed for production
            allocated_storage=10,  # GB
            multi_az=False,
            deletion_protection=False  # Change to True for production
        )


