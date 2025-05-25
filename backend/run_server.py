import uvicorn
import os
import sys
import socket

# Add the current directory to the path to make sure imports work
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def get_local_ip():
    """Get the local IP address of the machine"""
    try:
        # Create a socket to determine the local IP address
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))  # Connect to Google's DNS server
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception:
        return "127.0.0.1"  # Fallback to localhost

if __name__ == "__main__":
    # Get the local IP address
    local_ip = get_local_ip()
    print(f"Starting server on IP: {local_ip}")
    print(f"You can access the API at: http://{local_ip}:5000")
    print("Make sure this IP is set in your Flutter app's ApiService.baseUrl")
    
    # Use 0.0.0.0 to make the server accessible from other devices on the network
    # This is important for mobile app development
    uvicorn.run("main:app", host="0.0.0.0", port=5000, reload=True)