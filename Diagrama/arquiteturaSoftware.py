from diagrams import Diagram, Cluster, Edge
from diagrams.programming.language import Python
from diagrams.programming.framework import React, Spring
from diagrams.onprem.database import MySQL
from diagrams.aws.compute import Lambda

# Atributos para estilo do diagrama
graph_attr = {
    "splines": "ortho",
    "fontsize": "20",
}

# Atributos para as conexões pontilhadas
edge_attr = {
    "style": "dashed"
}

# Atributos para o Worker Service cluster
worker_cluster_attr = {
    "graph_attr": {
        "width": "3.0",  # Aumenta a largura
        "height": "2.0",
        "fixedsize": "true",
        "margin": "30"
    }
}

with Diagram("ARQUITETURA DE SOFTWARE", graph_attr=graph_attr, direction="LR"):
    
    # Database com descrição
    database = MySQL("Database\n\nArmazena os dados das\naplicações e usuários")

    with Cluster("Sistema", show=False):
        micro = Spring("MicroService\n\n\nCRUD de dados e regras\nde negócio")
        client = React("ClientSide Web\n\n\nVisualização do\nUsuário")
        
        # Força posicionamento vertical
        micro >> client
    
    with Cluster("Worker Service\n", graph_attr=worker_cluster_attr["graph_attr"]):
        worker = Lambda("Agendamento de tarefas\ne envio de notificações")
    
    with Cluster("Twilio API\n\nExterno: SMS e E-mail]"):
        twilio = Python("Executa o envio de\nnotificações")
    
    # Conexões com linhas pontilhadas
    database >> Edge(**edge_attr) >> micro
    worker >> Edge(**edge_attr) >> twilio
    client >> worker
