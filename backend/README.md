# BhojanBuddy Backend

This is the FastAPI backend for the BhojanBuddy application.

## Setup

1. Install dependencies:

```bash
# From the project root directory
python setup_backend.py
```

2. Run the server:

```bash
# From the project root directory
python run_server.py
```

## API Documentation

Once the server is running, you can access the API documentation at:

- Swagger UI: http://localhost:5000/docs
- ReDoc: http://localhost:5000/redoc

## Authentication

The API uses JWT token-based authentication. To authenticate:

1. Register a new user:

   - POST `/auth/register`
   - Body: `{"email": "user@example.com", "full_name": "User Name", "password": "password"}`

2. Login to get a token:

   - POST `/auth/login`
   - Form data: `username=user@example.com&password=password`

3. Use the token in subsequent requests:
   - Add header: `Authorization: Bearer {token}`

## Features

- User authentication and management
- BMI tracking with mode selection (Beast/Swasthya)
- Food logging with detailed nutritional information
- Image upload for food entries
