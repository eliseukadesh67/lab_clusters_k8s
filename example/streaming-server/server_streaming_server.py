import grpc 
from concurrent import futures 
import time 
import server_streaming_pb2 
import server_streaming_pb2_grpc 
 
class NumberServiceServicer(server_streaming_pb2_grpc.NumberServiceServicer): 
    def GenerateNumbers(self, request, context): 
        for i in range(request.start, request.start + 5): 
            print(f"Server sending: {i}") 
            yield server_streaming_pb2.NumberResponse(number=i) 
            time.sleep(1) 
 
def serve(): 
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10)) 
    server_streaming_pb2_grpc.add_NumberServiceServicer_to_server(NumberServiceServicer(), server) 
    server.add_insecure_port('[::]:50051') 
    server.start() 
    print("Server Streaming Server started on port 50051...") 
    try: 
        while True: 
            time.sleep(86400) 
    except KeyboardInterrupt: 
        server.stop(0) 
 
if __name__ == '__main__': 
    serve()