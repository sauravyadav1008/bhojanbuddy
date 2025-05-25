import os
from utils import split_dataset

# Get the absolute path to the project root
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

split_dataset(
    source_dir=os.path.join(project_root, "training", "dataset", "combined"),
    train_dir=os.path.join(project_root, "training", "dataset", "train"),
    val_dir=os.path.join(project_root, "training", "dataset", "val"),
    split_ratio=0.8
)