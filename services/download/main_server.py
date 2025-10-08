import os
from rest_service.download_rest_server import run_http_server
from grpc_service.download_server import run_grpc_server

protocol="rest"

def serve():
  protocol = os.getenv("PROTOCOL")
  
  if protocol == "grpc":
    run_grpc_server()
  else:
    run_http_server()

if __name__ == '__main__':
    serve()