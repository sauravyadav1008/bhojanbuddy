import os
import sys
import subprocess

# Get the absolute path to the backend directory
backend_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "backend")

# Change to the backend directory
os.chdir(backend_dir)

# Run the backend server
if __name__ == "__main__":
    print(f"Starting server from directory: {os.getcwd()}")
    
    # Run the main.py file directly instead of run_server.py to avoid recursion
    try:
        print("Starting BhojanBuddy server...")
        subprocess.run([sys.executable, "main.py"])
    except KeyboardInterrupt:
        print("\nServer stopped by user")
    except Exception as e:
        print(f"Error starting server: {e}")