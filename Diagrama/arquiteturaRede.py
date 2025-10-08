from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.client import Users
from diagrams.aws.network import InternetGateway, RouteTable, VPC, ELB
from diagrams.aws.compute import EC2, Lambda
from diagrams.aws.management import Cloudwatch
from diagrams.aws.integration import SNS
from diagrams.aws.storage import S3
from diagrams.custom import Custom
from diagrams.onprem.container import Docker

with Diagram("ARQUITETURA DE REDE", direction="LR", show=False):

    # Usuário e Rede
    usuario = Users("Usuário\nadministrador")
    rede = Custom("Rede", "./Imagens/rede.png")

    # Conexão externa
    usuario >> Edge(color="#4A4A4A") >> rede

    with Cluster("AWS", graph_attr={"style": "dashed"}):
        with Cluster("VPC", graph_attr={"style": "dashed"}):
            igw = InternetGateway("Internet Gateway")
            route_table = RouteTable("Route Table")
            lb = ELB("ELB")

            rede >> Edge(color="#4A4A4A") >> igw >> Edge(color="#4A4A4A") >> route_table >> Edge(color="#4A4A4A") >> lb

            # Subnets públicas
            with Cluster("Public Subnet 1", graph_attr={"style": "dashed", "color": "#90EE90"}):
                fe1 = EC2("Front-end")
                cw1 = Cloudwatch("CloudWatch")

            with Cluster("Public Subnet 2", graph_attr={"style": "dashed", "color": "#90EE90"}):
                fe2 = EC2("Front-end")
                cw2 = Cloudwatch("CloudWatch")

            lb >> Edge(color="#4A4A4A") >> [fe1, fe2]
            fe1 >> Edge(color="#4A4A4A") >> cw1
            fe2 >> Edge(color="#4A4A4A") >> cw2

            # Subnet privada
            with Cluster("Private Subnet", graph_attr={"style": "dashed", "color": "#FFB6C1"}):
                be = EC2("Back-end")
                bd = Docker("BD & Analytics")

            be >> Edge(color="#4A4A4A") >> bd
            route_table >> Edge(color="#4A4A4A") >> be

            # S3 Data Lake: RAW -> (Lambda TRUSTED) -> TRUSTED -> (Lambda CURED) -> CURED
            with Cluster("S3 Data Lake", graph_attr={"style": "dashed", "color": "#D4AC0D"}):
                s3_raw = S3("Raw")
                s3_trusted = S3("Trusted")
                s3_cured = S3("Refined")

            # Lambdas entre buckets (removida a lambda central)
            lambda_trusted = Lambda("Lambda Trusted")
            lambda_cured = Lambda("Lambda Refined")
            lambda_ = Lambda("Lambda")
            lambda_externa = Lambda("Lambda Externa")

            # Fluxo solicitado:
            # Backend escreve no RAW, depois processamento entre buckets:
            be >> Edge(color="#4A4A4A") >> s3_raw
            s3_raw >> Edge(color="#4A4A4A") >> lambda_trusted >> Edge(color="#4A4A4A") >> s3_trusted
            s3_trusted >> Edge(color="#4A4A4A") >> lambda_cured >> Edge(color="#4A4A4A") >> s3_cured

            # Twilio (notificações externas) ligado ao processamento de trusted (ajustável)
            twilio = Custom("Twilio", "./Imagens/twilio.png")

            # CloudWatch envia alerta
            alerta = Custom("Alerta", "./Imagens/alerta.png")
            cw1 >> Edge(color="#4A4A4A") >> alerta

            # SNS e e-mail
            sns = SNS("Amazon SNS")
            email = Custom("Email", "./Imagens/email.png")
            alerta >> sns >> email

            be >> Edge(color="#4A4A4A") >> lambda_
            lambda_ >> Edge(color="#4A4A4A") >> twilio

            # Internet (ícone adicionado) e integração externa
            internet = Custom("Internet", "./Imagens/rede.png")
            internet >> Edge(color="#4A4A4A") >> lambda_externa >> Edge(color="#4A4A4A") >> s3_cured
