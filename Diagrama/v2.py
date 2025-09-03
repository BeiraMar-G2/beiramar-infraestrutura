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
                    html = Custom("HTML", "./html.png")
                    css = Custom("CSS", "./css.png")
                    react = React("React")
                    js - html - css - react
                
                with Cluster("Backend JS", graph_attr=cluster_attr["graph_attr"]):
                    node = NodeJS("Node")
                    node - react
                
                web_stack = [js, html, css, node, react]
        
        # Usando um cluster com rank same para alinhar CRUD e Database
        with Cluster("Backend Services", graph_attr=cluster_attr["graph_attr"]):
            # Cluster CRUD dentro do AWS
            with Cluster("CRUD Service"):
                with Cluster("Docker"):
                    spring = Spring("Spring")
            
            # Cluster Database dentro do AWS
            with Cluster("Database Service"):
                with Cluster("Docker"):
                    mysql = MySQL("MySQL")
        
        python = Python("Python")
    
    twilio = Custom("Twilio", "./twilio.png")
    
    beneficiaria >> web_stack[0]  # Conecta beneficiária ao primeiro elemento do front-end (js)
    usuaria >> web_stack[0]
    web_stack[-1] >> spring
    spring - mysql
    python >> mysql
    twilio >> python