import grpc 
from concurrent import futures 
import time 
import client_streaming_pb2 
import client_streaming_pb2_grpc 
 
class StatsServiceServicer(client_streaming_pb2_grpc.StatsServiceServicer): 
    def ComputeAverage(self, request_iterator, context): 
        numbers = [] 
        for req in request_iterator: 
            print(f"Server received: {req.number}") 
            numbers.append(req.number) 
        avg = sum(numbers) / len(numbers) 
        return client_streaming_pb2.AverageResponse( 
            message=f"Processed {len(numbers)} guesses. Average: {avg:.2f}" 
        ) 
 
def serve(): 
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10)) 
    client_streaming_pb2_grpc.add_StatsServiceServicer_to_server(StatsServiceServicer(), server) 
    server.add_insecure_port('[::]:50051') 
    server.start() 
    print("Client Streaming Server started on port 50051...") 
    try: 
        while True: 
            time.sleep(86400) 
    except KeyboardInterrupt: 
        server.stop(0) 
 
if __name__ == '__main__': 
    serve() 