import grpc 
from concurrent import futures 
import time 
import bidirectional_pb2 
import bidirectional_pb2_grpc 
 
class ChatServiceServicer(bidirectional_pb2_grpc.ChatServiceServicer): 
    def Chat(self, request_iterator, context): 
        for message in request_iterator: 
            print(f"Received from {message.user}: {message.message}") 
            yield bidirectional_pb2.ChatMessage( 
                user="Server", message=f"Echo: {message.message}" 
            ) 
 
def serve(): 
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10)) 
    bidirectional_pb2_grpc.add_ChatServiceServicer_to_server(ChatServiceServicer(), server) 
    server.add_insecure_port('[::]:50051') 
    server.start() 
    print("Bidirectional Streaming Server started on port 50051...") 
    try: 
        while True: 
            time.sleep(86400) 
    except KeyboardInterrupt: 
        server.stop(0) 
 
if __name__ == '__main__': 
    serve()