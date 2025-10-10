import grpc 
import client_streaming_pb2 
import client_streaming_pb2_grpc 
 
def run(): 
    channel = grpc.insecure_channel('localhost:50051') 
    stub = client_streaming_pb2_grpc.StatsServiceStub(channel) 
 
    def generate_requests(): 
        for i in range(1, 6): 
            print(f"Sending guess: {i}") 
            yield client_streaming_pb2.NumberRequest(number=i) 
 
    response = stub.ComputeAverage(generate_requests()) 
    print("Server responded:", response.message) 
 
if __name__ == '__main__': 
    run()