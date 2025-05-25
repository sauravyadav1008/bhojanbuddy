import os
import json
from PIL import Image
import tensorflow as tf
import matplotlib.pyplot as plt
from collections import Counter
import numpy as np

# Enable mixed precision
mixed_precision = tf.keras.mixed_precision
layers = tf.keras.layers
models = tf.keras.models
MobileNetV3Small = tf.keras.applications.MobileNetV3Small
preprocess_input = tf.keras.applications.mobilenet_v3.preprocess_input
mixed_precision.set_global_policy('mixed_float16')

# Config
IMAGE_SIZE = (224, 224)
BATCH_SIZE = 16  # Reduced for faster training and less memory
EPOCHS = 12  # Single phase, adjusted for ~30-40 min training
NUM_CLASSES_TO_CHECK = 5  # Number of validation images to check predictions

# Directories
base_dir = os.path.dirname(os.path.abspath(__file__))
train_dir = os.path.join(base_dir, "dataset", "train")
val_dir = os.path.join(base_dir, "dataset", "val")
model_dir = os.path.join(os.path.dirname(base_dir), "model")
os.makedirs(model_dir, exist_ok=True)

# Debug directories
print(f"Base dir: {base_dir}")
print(f"Train dir: {train_dir} (exists? {os.path.exists(train_dir)})")
print(f"Validation dir: {val_dir} (exists? {os.path.exists(val_dir)})")
print(f"Model dir: {model_dir} (exists? {os.path.exists(model_dir)})")

# ----------------------------- Clean Dataset -----------------------------

def clean_directory(directory):
    print(f"🧹 Cleaning dataset: {directory}")
    supported_ext = ('.jpg', '.jpeg', '.png', '.bmp', '.gif')
    removed = 0
    for root, _, files in os.walk(directory):
        for file in files:
            path = os.path.join(root, file)
            try:
                if not file.lower().endswith(supported_ext):
                    raise ValueError("Unsupported file extension")
                with Image.open(path) as img:
                    img.verify()
                raw = tf.io.read_file(path)
                _ = tf.io.decode_image(raw)
            except Exception as e:
                print(f"❌ Removing {path}: {e}")
                os.remove(path)
                removed += 1
    print(f"✅ Removed {removed} invalid images from {directory}")

clean_directory(train_dir)
clean_directory(val_dir)

# ----------------------------- Check Class Balance -----------------------------

def check_class_balance(directory):
    print(f"📊 Checking class balance in {directory}")
    for class_name in os.listdir(directory):
        class_path = os.path.join(directory, class_name)
        if os.path.isdir(class_path):
            num_images = len([f for f in os.listdir(class_path) if f.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp', '.gif'))])
            print(f"Class {class_name}: {num_images} images")

check_class_balance(train_dir)
check_class_balance(val_dir)

# ----------------------------- Load Dataset -----------------------------

train_ds = tf.keras.utils.image_dataset_from_directory(
    train_dir,
    image_size=IMAGE_SIZE,
    batch_size=BATCH_SIZE,
    label_mode='categorical'
)
val_ds = tf.keras.utils.image_dataset_from_directory(
    val_dir,
    image_size=IMAGE_SIZE,
    batch_size=BATCH_SIZE,
    label_mode='categorical'
)

class_names = train_ds.class_names
label_map = {i: name for i, name in enumerate(class_names)}
with open(os.path.join(model_dir, "label_map.json"), "w") as f:
    json.dump(label_map, f)

# Compute class weights
train_labels = np.concatenate([y.numpy() for _, y in train_ds])
class_counts = Counter(np.argmax(train_labels, axis=1))
total_samples = sum(class_counts.values())
class_weights = {i: total_samples / (len(class_counts) * count) for i, count in class_counts.items()}
print(f"Class weights: {class_weights}")

# Aggressive data augmentation
data_augmentation = tf.keras.Sequential([
    layers.RandomFlip("horizontal_and_vertical"),
    layers.RandomRotation(0.3),
    layers.RandomZoom(0.3),
    layers.RandomContrast(0.3),
    layers.RandomBrightness(0.3),
    layers.RandomTranslation(0.2, 0.2),
    layers.RandomCrop(IMAGE_SIZE[0], IMAGE_SIZE[1])  # Ensure size after crop
])

# Apply augmentation and preprocessing
train_ds = train_ds.map(lambda x, y: (data_augmentation(x, training=True), y)).map(lambda x, y: (preprocess_input(x), y))
val_ds = val_ds.map(lambda x, y: (preprocess_input(x), y))

AUTOTUNE = tf.data.AUTOTUNE
train_ds = train_ds.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)

# ----------------------------- Build Model -----------------------------

base_model = MobileNetV3Small(
    include_top=False,
    weights='imagenet',
    input_shape=(*IMAGE_SIZE, 3)
)
base_model.trainable = False  # Freeze for simplicity

model = models.Sequential([
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.BatchNormalization(),
    layers.Dense(256, activation='relu'),  # Simplified architecture
    layers.Dropout(0.5),
    layers.Dense(len(class_names), activation='softmax', dtype='float32')
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),  # Higher for faster convergence
    loss='categorical_crossentropy',
    metrics=['accuracy', tf.keras.metrics.TopKCategoricalAccuracy(k=5)]
)

model.summary()

# ----------------------------- Callbacks -----------------------------

checkpoint_cb = tf.keras.callbacks.ModelCheckpoint(
    filepath=os.path.join(model_dir, "final_model.h5"),
    monitor="val_accuracy",
    save_best_only=True,
    mode="max"
)

callbacks = [
    checkpoint_cb,
    tf.keras.callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=2),
    tf.keras.callbacks.EarlyStopping(monitor="val_loss", patience=4, restore_best_weights=True)
]

# ----------------------------- Train Model -----------------------------

print("\n🚀 Training model...")
history = model.fit(train_ds, validation_data=val_ds, epochs=EPOCHS, callbacks=callbacks, class_weight=class_weights)

# ----------------------------- Check Predictions -----------------------------

def check_predictions(model, dataset, class_names, num_images=NUM_CLASSES_TO_CHECK):
    print("\n🔍 Checking predictions on validation set...")
    iterator = iter(dataset)
    images, labels = next(iterator)
    predictions = model.predict(images)
    for i in range(min(num_images, len(images))):
        pred_class = class_names[np.argmax(predictions[i])]
        true_class = class_names[np.argmax(labels[i])]
        confidence = np.max(predictions[i])
        print(f"Image {i+1}: Predicted: {pred_class} ({confidence:.2%}), True: {true_class}")

check_predictions(model, val_ds, class_names)

# ----------------------------- Plot Training History -----------------------------

def plot_history(history, phase="Training"):
    acc = history.history['accuracy']
    val_acc = history.history['val_accuracy']
    loss = history.history['loss']
    val_loss = history.history['val_loss']
    epochs = range(1, len(acc) + 1)

    plt.figure(figsize=(12, 4))
    plt.subplot(1, 2, 1)
    plt.plot(epochs, acc, 'b', label='Training acc')
    plt.plot(epochs, val_acc, 'r', label='Validation acc')
    plt.title(f'{phase} Accuracy')
    plt.legend()

    plt.subplot(1, 2, 2)
    plt.plot(epochs, loss, 'b', label='Training loss')
    plt.plot(epochs, val_loss, 'r', label='Validation loss')
    plt.title(f'{phase} Loss')
    plt.legend()

    plt.savefig(os.path.join(model_dir, f"{phase}_plot.png"))
    plt.close()

plot_history(history)

# ----------------------------- Save Model & Convert to TFLite -----------------------------

saved_model_path = os.path.join(model_dir, "saved_model")
model.save(saved_model_path, save_format="tf")
model.save(os.path.join(model_dir, "food_model_final.h5"))

converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_path)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS,
    tf.lite.OpsSet.SELECT_TF_OPS
]

try:
    tflite_model = converter.convert()
    tflite_path = os.path.join(model_dir, "food_model.tflite")
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)
    print(f"✅ TFLite model saved to {tflite_path}")
except Exception as e:
    print(f"❌ TFLite conversion failed: {e}")

# ----------------------------- Save Training History -----------------------------

def serialize_history(hist):
    return {k: [float(v) for v in val] for k, val in hist.items()}

with open(os.path.join(model_dir, "training_history.json"), "w") as f:
    json.dump({"training": serialize_history(history.history)}, f)

print("\n✅ Training complete. Model saved for both web & mobile.")