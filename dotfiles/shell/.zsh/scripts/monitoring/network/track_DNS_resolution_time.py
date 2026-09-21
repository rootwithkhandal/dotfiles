import socket
import time

def dns_resolution_time(hostname):
    start_time = time.time()
    try:
        socket.gethostbyname(hostname)
        end_time = time.time()
        return end_time - start_time
    except socket.error as err:
        print(f"Error: {err}")
        return None

if __name__ == "__main__":
    hostname = "www.example.com"
    resolution_time = dns_resolution_time(hostname)
    if resolution_time:
        print(f"DNS resolution time for {hostname}: {resolution_time:.6f} seconds")