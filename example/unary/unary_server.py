import grpc
from concurrent import futures
import time
import unary_pb2
import unary_pb2_grpc

class EchoServiceServicer(unary_pb2_grpc.EchoServiceServicer): 
    def Echo(self, request, context): 
        print(f"Server received: {request.message}") 
        return unary_pb2.EchoResponse(message=f"Recebido: {request.message}") 
 
def serve(): 
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10)) 
    unary_pb2_grpc.add_EchoServiceServicer_to_server(EchoServiceServicer(), server) 
    server.add_insecure_port('[::]:50051') 
    server.start() 
    print("Unary Server started on port 50051...") 
    try: 
        while True: 
            time.sleep(86400) 
    except KeyboardInterrupt: 
        server.stop(0) 
 
if __name__ == '__main__': 
    serve()