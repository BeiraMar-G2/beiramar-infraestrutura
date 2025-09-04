from diagrams import Diagram, Cluster, Edge
from diagrams.programming.framework import React, Spring
from diagrams.onprem.database import MySQL
from diagrams.aws.compute import Lambda
from diagrams.programming.language import Python

# Estilo do grafo
graph_attr = {
    "splines": "ortho",
    "fontsize": "20",
    "pad": "0.5"
}
dash = {"style": "dashed"}

with Diagram("ARQUITETURA DE SOFTWARE", graph_attr=graph_attr, direction="LR"):

    # Banco de dados
    db = MySQL("Database\n[Container: MySQL]\n\nArmazena os dados das\naplicações e usuários")

    # Cluster do sistema com orientação vertical
    with Cluster("Sistema", graph_attr={"rankdir": "TB"}):
        with Cluster("MicroService"):
            micro = Spring("MicroService\n[Container: Spring Boot]\n\nCRUD de dados e regras\nde negócio")

        with Cluster("ClientSide Web"):
            client = React("ClientSide Web\n[Container: React]\n\nVisualização do Usuário")

        # Aresta invisível para forçar posicionamento vertical
        micro >> Edge(style="invis") >> client

    # Cluster do Worker Service
    with Cluster("Worker Service\n[Container: Python + AWS Lambda]"):
        worker = Lambda("Agendamento de tarefas\ne envio de notificações")

    # Cluster da API externa Twilio
    with Cluster("Twilio API\n[Serviço Externo: SMS e E-mail]"):
        twilio = Python("Executa o envio de\nnotificações")

    # Conexões entre os componentes
    db >> micro
    micro >> worker
    worker >> twilio
