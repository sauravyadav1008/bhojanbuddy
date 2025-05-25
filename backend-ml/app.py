from flask import Flask, request, jsonify
import tensorflow as tf
import numpy as np
import json
import os
import sys
from PIL import Image
from flask_cors import CORS

# Add the project root to the Python path when running directly
if __name__ == "__main__":
    sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from backend.config import IMAGE_SIZE

app = Flask(__name__)
CORS(app)

# Define model directory path
MODEL_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "model")
os.makedirs(MODEL_DIR, exist_ok=True)

# Create placeholder model files if they don't exist
if not os.path.exists(os.path.join(MODEL_DIR, "food_model.h5")):
    print("Warning: Model file not found. Please train the model first.")
    # Create a simple placeholder model for development
    simple_model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(224, 224, 3)),
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dense(10, activation='softmax')
    ])
    simple_model.compile(optimizer='adam', loss='categorical_crossentropy')
    simple_model.save(os.path.join(MODEL_DIR, "food_model.h5"))

# Create placeholder label map if it doesn't exist
if not os.path.exists(os.path.join(MODEL_DIR, "label_map.json")):
    print("Warning: Label map not found. Creating placeholder.")
    with open(os.path.join(MODEL_DIR, "label_map.json"), "w") as f:
        json.dump({"0": "placeholder_food"}, f)

# Create placeholder nutrition DB if it doesn't exist
if not os.path.exists(os.path.join(MODEL_DIR, "nutrition_db.json")):
    print("Warning: Nutrition database not found. Creating placeholder.")
    with open(os.path.join(MODEL_DIR, "nutrition_db.json"), "w") as f:
        json.dump({"placeholder_food": {"calories": 100}}, f)

# Load model
model = tf.keras.models.load_model(os.path.join(MODEL_DIR, "food_model.h5"))

# Load label map
with open(os.path.join(MODEL_DIR, "label_map.json"), "r") as f:
    label_map = json.load(f)

# Load nutrition DB
with open(os.path.join(MODEL_DIR, "nutrition_db.json"), "r") as f:
    nutrition_data = json.load(f)

# Feedback file
FEEDBACK_PATH = os.path.join(MODEL_DIR, "user_feedback.json")
# Create data directory for uploaded images
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
os.makedirs(DATA_DIR, exist_ok=True)
if not os.path.exists(FEEDBACK_PATH):
    with open(FEEDBACK_PATH, "w") as f:
        json.dump([], f)

CONFIDENCE_THRESHOLD = 0.7


def preprocess_image(image_path):
    """Load and preprocess image for prediction with RGBA handling."""
    img = Image.open(image_path)
    
    # Convert palette or images with transparency to RGBA, then to RGB
    if img.mode in ("P", "LA") or (img.mode == "RGBA" and "transparency" in img.info):
        img = img.convert("RGBA").convert("RGB")
    else:
        img = img.convert("RGB")

    img = img.resize(IMAGE_SIZE)
    img = np.array(img) / 255.0
    return np.expand_dims(img, axis=0)



def log_user_feedback(image_name, correct_label, predicted_label, confidence):
    with open(FEEDBACK_PATH, "r") as f:
        feedback = json.load(f)
    feedback.append({
        "image_name": image_name,
        "correct_label": correct_label,
        "predicted_label": predicted_label,
        "confidence": confidence
    })
    with open(FEEDBACK_PATH, "w") as f:
        json.dump(feedback, f, indent=2)


@app.route("/", methods=["GET"])
def index():
    return jsonify({
        "message": "BhojanBuddy API is running",
        "endpoints": {
            "/predict": "POST - Upload an image for food recognition",
            "/feedback": "POST - Submit feedback for predictions"
        }
    })


@app.route("/predict", methods=["POST", "GET"])
def predict():
    if request.method == "GET":
        return jsonify({
            "message": "This endpoint requires a POST request with an image file",
            "usage": {
                "method": "POST",
                "content-type": "multipart/form-data",
                "form-data": {
                    "image": "(file) - The food image to analyze"
                }
            }
        })
        
    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    image_file = request.files["image"]
    image_path = os.path.join(DATA_DIR, image_file.filename)
    image_file.save(image_path)

    img_tensor = preprocess_image(image_path)
    preds = model.predict(img_tensor)[0]
    top_indices = preds.argsort()[-3:][::-1]

    top_predictions = [
        {"label": label_map[str(i)], "confidence": float(preds[i])}
        for i in top_indices
    ]

    if top_predictions[0]["confidence"] < CONFIDENCE_THRESHOLD:
        return jsonify({
            "status": "uncertain",
            "options": top_predictions
        })

    label = top_predictions[0]["label"]
    nutrition = nutrition_data.get(label, {})
    return jsonify({
        "status": "confident",
        "predicted_label": label,
        "confidence": top_predictions[0]["confidence"],
        "nutrition": nutrition
    })


@app.route("/feedback", methods=["POST", "GET"])
def feedback():
    if request.method == "GET":
        return jsonify({
            "message": "This endpoint requires a POST request with JSON data",
            "usage": {
                "method": "POST",
                "content-type": "application/json",
                "json_body": {
                    "image_name": "Name of the image file",
                    "correct_label": "The correct food label",
                    "predicted_label": "The label predicted by the model",
                    "confidence": "The confidence score of the prediction"
                }
            }
        })
        
    data = request.get_json()
    required_fields = ["image_name", "correct_label", "predicted_label", "confidence"]
    if not all(field in data for field in required_fields):
        return jsonify({"error": "Missing required fields."}), 400

    log_user_feedback(
        image_name=data["image_name"],
        correct_label=data["correct_label"],
        predicted_label=data["predicted_label"],
        confidence=data["confidence"]
    )
    return jsonify({"message": "Feedback recorded."})


if __name__ == "__main__":
    app.run(debug=True)