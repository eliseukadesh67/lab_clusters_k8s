import grpc 
import server_streaming_pb2 
import server_streaming_pb2_grpc 
 
def run(): 
    channel = grpc.insecure_channel('localhost:50051') 
    stub = server_streaming_pb2_grpc.NumberServiceStub(channel) 
    responses = stub.GenerateNumbers(server_streaming_pb2.NumberRequest(start=1)) 
    for response in responses: 
        print("Client received:", response.number) 
 
if __name__ == '__main__': 
    run()