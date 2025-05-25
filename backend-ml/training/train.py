import os
import json
from PIL import Image
import tensorflow as tf


# Enable mixed precision if available
mixed_precision = tf.keras.mixed_precision
layers = tf.keras.layers
models = tf.keras.models
EfficientNetV2B0 = tf.keras.applications.efficientnet_v2.EfficientNetV2B0
preprocess_input = tf.keras.applications.efficientnet_v2.preprocess_input
mixed_precision.set_global_policy('mixed_float16')

# Config
IMAGE_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS_PHASE1 = 15
EPOCHS_PHASE2 = 10

# Directories
base_dir = os.path.dirname(os.path.abspath(__file__))
train_dir = os.path.join(base_dir, "dataset/train")
val_dir = os.path.join(base_dir, "dataset/val")
model_dir = os.path.join(os.path.dirname(base_dir), "model")
os.makedirs(model_dir, exist_ok=True)

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
    print(f"✅ Removed {removed} invalid or unsupported images from {directory}")

clean_directory(train_dir)
clean_directory(val_dir)

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

# Apply EfficientNet-specific preprocessing
train_ds = train_ds.map(lambda x, y: (preprocess_input(x), y))
val_ds = val_ds.map(lambda x, y: (preprocess_input(x), y))

AUTOTUNE = tf.data.AUTOTUNE
train_ds = train_ds.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)

# ----------------------------- Build Model -----------------------------

base_model = EfficientNetV2B0(
    include_top=False,
    weights='imagenet',
    input_shape=(*IMAGE_SIZE, 3)
)
base_model.trainable = False

model = models.Sequential([
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.BatchNormalization(),
    layers.Dense(512, activation='relu'),
    layers.Dropout(0.4),
    layers.Dense(256, activation='relu'),
    layers.Dropout(0.3),
    layers.Dense(len(class_names), activation='softmax', dtype='float32')  # For mixed precision
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),  # Lower LR for Phase 1
    loss='categorical_crossentropy',
    metrics=['accuracy', tf.keras.metrics.TopKCategoricalAccuracy(k=5)]
)

# ----------------------------- Callbacks -----------------------------

checkpoint_cb = tf.keras.callbacks.ModelCheckpoint(
    filepath=os.path.join(model_dir, "best_model.h5"),
    monitor="val_accuracy",
    save_best_only=True,
    mode="max"
)

callbacks = [
    checkpoint_cb,
    tf.keras.callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=2),
    tf.keras.callbacks.EarlyStopping(monitor="val_loss", patience=5, restore_best_weights=True)
]

# ----------------------------- Train Phase 1 -----------------------------

print("\n🚀 Phase 1: Training with frozen base model...")
history1 = model.fit(train_ds, validation_data=val_ds, epochs=EPOCHS_PHASE1, callbacks=callbacks)

# ----------------------------- Fine-Tune Phase 2 -----------------------------

print("\n🔧 Phase 2: Fine-tuning base model...")
base_model.trainable = True
for layer in base_model.layers[:-10]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(1e-5),  # Lower LR for fine-tuning
    loss='categorical_crossentropy',
    metrics=['accuracy', tf.keras.metrics.TopKCategoricalAccuracy(k=5)]
)

history2 = model.fit(train_ds, validation_data=val_ds, epochs=EPOCHS_PHASE2, callbacks=callbacks)

# ----------------------------- Save Model & TFLite -----------------------------

model.save(os.path.join(model_dir, "food_model_final.h5"))

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()
with open(os.path.join(model_dir, "food_model.tflite"), "wb") as f:
    f.write(tflite_model)

# ----------------------------- Save Training History -----------------------------

def serialize_history(hist):
    return {k: [float(v) for v in val] for k, val in hist.items()}

with open(os.path.join(model_dir, "training_history.json"), "w") as f:
    json.dump({
        "phase1": serialize_history(history1.history),
        "phase2": serialize_history(history2.history)
    }, f)

print("\n✅ Training complete. Model saved for both web & mobile.")
