# BhojanBuddy Integration Guide

This guide explains how to connect the Flutter frontend with the FastAPI backend.

## Backend Setup

1. Install the required Python packages:

```bash
cd backend
pip install -r requirements.txt
```

2. Run the backend server:

```bash
# From the project root directory
python run_server.py
```

The server will start at `http://127.0.0.1:5000` by default.

## Frontend Configuration

The Flutter app is already configured to connect to the backend. The API service is set up to try multiple URLs:

- `http://10.0.2.2:5000` (default for Android emulator)
- `http://localhost:5000`
- `http://127.0.0.1:5000`

If you need to use a different URL, you can configure it in the app settings.

## Authentication Flow

1. **Registration**: Users can register with their email, name, and password.
2. **Login**: After registration, users can log in to get an access token.
3. **Token Storage**: The token is stored in SharedPreferences and used for all authenticated requests.

## Features Implemented

### User Management

- Registration and login
- Profile management
- Mode preference (Beast/Swasthya)

### BMI Tracking

- Save BMI records with mode selection
- View BMI history

### Food Logging

- Log food entries with images
- Track detailed nutritional information
- View food history

## API Endpoints

### Authentication

- `POST /auth/register` - Register a new user
- `POST /auth/login` - Login and get access token

### User Management

- `GET /users/me` - Get current user profile
- `PUT /users/me` - Update user profile
- `GET /users/{user_id}` - Get user by ID

### BMI

- `POST /api/bmi` - Create a new BMI record
- `GET /api/bmi/{user_id}` - Get BMI history for a user

### Food

- `POST /foods/log` - Log a new food entry with image
- `GET /foods/history/{user_id}` - Get food history for a user

## Testing the Integration

1. Start the backend server
2. Run the Flutter app
3. Register a new user or log in
4. Test the BMI calculation and food logging features
