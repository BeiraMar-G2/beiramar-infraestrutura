from diagrams import Diagram, Cluster, Edge
from diagrams.programming.language import Python, Java
from diagrams.programming.framework import React
from diagrams.onprem.database import MySQL
from diagrams.aws.compute import Lambda



with Diagram("Arquitetura de Software", direction="TB"):
    
   
    database = MySQL("Database\n[Container: MySQL]")
    
    with Cluster("Sistema"):
        micro = Java("CRUD de dados e regras\nde negócio")
        client = React("Visualização do\nUsuário")

        # força microservice ficar em cima do client
        micro >> Edge(style="invis") >> client
    
        database >> micro
   
    with Cluster("Worker Service\n[Container: Python + AWS Lambda]"):
        worker = Lambda("Agendamento de tarefas\ne envio de notificações")
    
   
    with Cluster("Twilio API\n[Container: Serviço Externo]"):
        twilio = Python("Executa o envio de\nnotificações\nSMS e E-mail")

    worker >> micro
    worker >> twilio
