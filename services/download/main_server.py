import os
from rest_service.download_rest_server import run_http_server
from grpc_service.download_server import run_grpc_server

import logging

logging.basicConfig(
    level=logging.INFO, 
    format='%(asctime)s - %(levelname)s - %(message)s'
)


def serve():
  protocol = os.getenv("PROTOCOL")
  logging.info(f"Iniciando em modo {protocol}")
  if protocol == "grpc":
    run_grpc_server()
  else:
    run_http_server()

if __name__ == '__main__':
    serve()