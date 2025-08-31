from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.client import Users
from diagrams.aws.network import InternetGateway, RouteTable, VPC
from diagrams.aws.compute import EC2, Lambda
from diagrams.aws.network import ELB
from diagrams.aws.management import Cloudwatch
from diagrams.aws.integration import SNS
from diagrams.aws.storage import S3
from diagrams.custom import Custom
from diagrams.onprem.container import Docker

with Diagram("Arquitetura de Rede", direction="LR"):

    usuario = Users("Usuário administrador")

    with Cluster("AWS", graph_attr={"style": "dashed, filled", "color": "#FFFCF5", "penwidth": "3", "pencolor": "orange"}):
        
        aws_logo = Custom("", "./logo_aws.png")

        with Cluster("VPC", graph_attr={"style": "dashed,filled", "color": "#FFCA69", "penwidth": "2", "pencolor": "orange"}):
            
            igw = InternetGateway("Internet Gateway")
            route_table = RouteTable("Route Table")
            lb = ELB("ELB")

            usuario >> Edge(color="Black") << igw  >> Edge(color="Black") << route_table >> Edge(color="Black") << lb

            with Cluster("Public Subnet 1", graph_attr={"style": "dashed,filled", "color": "lightgreen", "pencolor": "green"}):
               
                fe1 = EC2("Front-end 1")
                cw1 = Cloudwatch("CloudWatch")
                lb >> fe1
                fe1 >> cw1

            with Cluster("Public Subnet 2", graph_attr={"style": "dashed,filled", "color": "lightgreen", "pencolor": "green"}):
                fe2 = EC2("Front-end 2")
                cw2 = Cloudwatch("CloudWatch")
                lb >> fe2
                fe2 >> cw2

            with Cluster("Private Subnet", graph_attr={"style": "dashed,filled", "color": "#FFFFF", "pencolor": "red"}):
                be = EC2("Back-end")
                banco = Docker("Banco Docker")
                cw3 = Cloudwatch("CloudWatch")
                be>> cw3
                be >> banco

            # Ligações de rota  
            route_table >> Edge(color="Black") << be >> cw3

        

            # Buckets S3 e Lambda
            with Cluster("S3 Buckets", graph_attr={"style": "dashed,filled", "color": "#FFF3CD", "pencolor": "gold"}):
                s3_raw = S3("RAW")
                s3_trusted = S3("TRUSTED")
                s3_cured = S3("CURED")

            lambda_func = Lambda("Lambda")
            be >> lambda_func
            lambda_func >> s3_raw
