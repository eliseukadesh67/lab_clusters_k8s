import grpc 
import time 
import bidirectional_pb2 
import bidirectional_pb2_grpc 
 
def run(): 
    channel = grpc.insecure_channel('localhost:50051') 
    stub = bidirectional_pb2_grpc.ChatServiceStub(channel) 
 
    def generate_messages(): 
        for i in range(1, 4): 
            msg = input(f"Enter message {i}: ") 
            yield bidirectional_pb2.ChatMessage(user="Client", message=msg) 
            time.sleep(1) 
 
    responses = stub.Chat(generate_messages()) 
    for response in responses: 
        print(f"Received from server: {response.message}") 
 
if __name__ == '__main__': 
    run()