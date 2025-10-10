import grpc 
import unary_pb2 
import unary_pb2_grpc 
 
def run(): 
    channel = grpc.insecure_channel('localhost:50051') 
    stub = unary_pb2_grpc.EchoServiceStub(channel) 
    response = stub.Echo(unary_pb2.EchoRequest(message="olá")) 
    print("Client received:", response.message) 
 
if __name__ == '__main__': 
    run() 