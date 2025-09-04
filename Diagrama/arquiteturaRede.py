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

    rede_custom = Custom("Rede", "./Imagens/rede.png")

    with Cluster("AWS", graph_attr={"style": "dashed, filled", "color": "#F5F5F5", "penwidth": "2", "pencolor": "#A9A9A9"}):
        
        aws_logo = Custom("", "./logo_aws.png")

        with Cluster("VPC", graph_attr={"style": "dashed,filled", "color": "#E0E0E0", "penwidth": "2", "pencolor": "#B0B0B0"}):
            
            igw = InternetGateway("Internet Gateway")
            route_table = RouteTable("Route Table")
            lb = ELB("ELB")

            usuario >> Edge(color="#4A4A4A") << rede_custom >> Edge(color="#4A4A4A") << igw
            igw >> Edge(color="#4A4A4A") << route_table >> Edge(color="#4A4A4A") << lb

            with Cluster("Public Subnet 1", graph_attr={"style": "dashed,filled", "color": "#D6EAF8", "pencolor": "#5DADE2"}):
                fe1 = EC2("Front-end 1")
                cw1 = Cloudwatch("CloudWatch")
                lb >> fe1
                fe1 >> cw1

            with Cluster("Public Subnet 2", graph_attr={"style": "dashed,filled", "color": "#D6EAF8", "pencolor": "#5DADE2"}):
                fe2 = EC2("Front-end 2")
                cw2 = Cloudwatch("CloudWatch")
                lb >> fe2
                fe2 >> cw2

            with Cluster("Private Subnet", graph_attr={"style": "dashed,filled", "color": "#F2F3F4", "pencolor": "#7D7D7D"}):
                be = EC2("Back-end")
                banco = Docker("Banco Docker")
                cw3 = Cloudwatch("CloudWatch")
                be >> banco

            route_table >> Edge(color="#4A4A4A") << be >> cw3

            with Cluster("S3 Buckets", graph_attr={"style": "dashed,filled", "color": "#FEF9E7", "pencolor": "#D4AC0D"}):
                s3_raw = S3("RAW")
                s3_trusted = S3("TRUSTED")
                s3_cured = S3("CURED")

            lambda_func = Lambda("Lambda")
            be >> lambda_func
            lambda_func >> s3_raw

            s3_extra = S3("Bucket Upload de Imagens")
            be >> s3_extra
            
           
            sns = SNS("Amazon SNS")
            alerta = Custom("Alerta", "./Imagens/alerta.png")
            cw1 >> alerta
            alerta >> sns
            email = Custom("Email", "./Imagens/email.png")
            sns >> email