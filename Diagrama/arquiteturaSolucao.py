from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import ECS
from diagrams.programming.framework import React, Spring, Flask
from diagrams.programming.language import Python, JavaScript, NodeJS
from diagrams.onprem.database import MySQL
from diagrams.custom import Custom
from diagrams.aws.general import Users

graph_attr = {
    "splines": "ortho",
    "rankdir": "LR",
    "pad": "0.5"
}

cluster_attr = {
    "graph_attr": {
        "rankdir": "LR",
        "rank": "same"
    }
}

with Diagram("DIAGRAMA DE SOLUÇÃO", show=True, direction="LR", graph_attr=graph_attr):
    
    beneficiaria = Users("Beneficiária")
    usuaria = Users("Usuária")
    
    # Cluster AWS principal
    with Cluster("AWS Cloud"):
        
        # Cluster para Web Application
        with Cluster("WEB APLICAÇÃO"):
            with Cluster("Docker"):
                with Cluster("Front-end", graph_attr=cluster_attr["graph_attr"]):
                    js = JavaScript("JS")
                    html = Custom("HTML", "./Imagens/html.png")
                    css = Custom("CSS", "./Imagens/css.png")
                    react = React("React")
                    js - html - css - react
                
                node = NodeJS("Node")
                web_stack = [js, html, css, node, react]
                
                node >> web_stack[0]  # Conecta o Node ao início do front-end
                
                
        
        # Usando um cluster com rank same para alinhar CRUD e Database
        with Cluster("Backend Services", graph_attr=cluster_attr["graph_attr"]):
            # Cluster CRUD dentro do AWS
            with Cluster("Docker"):
                spring = Spring("Spring")
            
            # Cluster Database dentro do AWS
        with Cluster("Database Service"):
            with Cluster("Docker"):
                mysql = MySQL("MySQL")

        

        # Timer fora do cluster
        timer = Custom("Gatilho", "./Imagens/relogio.png")
        
        # Cluster apenas para o Python
        with Cluster("Lambda"):
            python = Python("Python")
        
        # Conecta timer ao Python
        timer - python
    
    # Cluster de Mensageria com SMS e Email à esquerda do Twilio
    with Cluster("Mensageria"):
        email = Custom("Email", "./Imagens/email.png")
        sms = Custom("SMS", "./Imagens/sms.png")
        twilio = Custom("Twilio", "./Imagens/twilio.png")

        mensageria = [email, sms, twilio]

        # Conecta Email e SMS ao Twilio horizontalmente
        email - sms << twilio

    # Mantém as conexões existentes e adiciona conexões com usuária
    beneficiaria >> web_stack[0]
    usuaria >> web_stack[0]
    usuaria << mensageria[0]  # Conecta usuária ao Email e SMS
    web_stack[-1] >> spring
    spring - mysql
    python >> mysql
    twilio >> python
    python >> twilio