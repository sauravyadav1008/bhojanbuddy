import os
import shutil
import random

def split_dataset(source_dir, train_dir, val_dir, split_ratio=0.8):
    os.makedirs(train_dir, exist_ok=True)
    os.makedirs(val_dir, exist_ok=True)

    for class_name in os.listdir(source_dir):
        class_path = os.path.join(source_dir, class_name)
        if not os.path.isdir(class_path):
            continue

        images = os.listdir(class_path)
        random.shuffle(images)
        split_idx = int(len(images) * split_ratio)

        for img in images[:split_idx]:
            src = os.path.join(class_path, img)
            dst_dir = os.path.join(train_dir, class_name)
            os.makedirs(dst_dir, exist_ok=True)
            shutil.copy(src, dst_dir)

        for img in images[split_idx:]:
            src = os.path.join(class_path, img)
            dst_dir = os.path.join(val_dir, class_name)
            os.makedirs(dst_dir, exist_ok=True)
            shutil.copy(src, dst_dir)