# IntegriScan Backend - AI Pipeline for Skin/Scalp Disease Classification

This backend provides a complete AI pipeline for classifying skin and scalp diseases on Filipino skin tones (Fitzpatrick Types IV & V). The pipeline includes:

1. **Image Preprocessing**: CLAHE for contrast enhancement and DullRazor for hair removal
2. **Model Training**: Fine-tuning EfficientNetV2-B0 backbone for disease classification
3. **Model Export**: Converting to TensorFlow Lite with FP16/INT8 quantization for Flutter deployment

## Directory Structure

```
backend/
├── __init__.py
├── preprocess.py      # Image preprocessing pipeline
├── train.py           # Model training and fine-tuning
├── export.py          # Model quantization and export
├── requirements.txt   # Python dependencies
�└── README.md          # This file
```

## Installation

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Usage

### 1. Image Preprocessing

Enhance lesion contrast and remove hair from images:

```bash
python preprocess.py --input path/to/image.jpg --output path/to/output.jpg
```

For batch processing:
```bash
python preprocess.py --input path/to/input_dir/ --output path/to/output_dir/ --batch
```

Options:
- `--no-clahe`: Skip CLAHE contrast enhancement
- `--no-dullrazor`: Skip DullRazor hair removal

### 2. Model Training

Train/fine-tune the EfficientNetV2-B0 model:

```bash
python train.py --data_dir path/to/training_data/ --num_classes 5
```

Training data should be organized in subdirectories per class:
```
training_data/
├── class_1/
│   ├── img1.jpg
│   └── img2.jpg
├── class_2/
│   ├── img3.jpg
│   └── img4.jpg
�└── ...
```

Key training options:
- `--batch_size`: Batch size (default: 32)
- `--num_epochs`: Number of epochs (default: 50)
- `--learning_rate`: Learning rate (default: 0.001)
- `--use_focal_loss`: Use Focal Loss for class imbalance
- `--unfreeze_epoch`: Epoch to unfreeze backbone (default: 10)

### 3. Model Export

Export trained model to TensorFlow Lite:

```bash
python export.py --model_path path/to/model.pth --num_classes 5 --quantization fp16
```

For INT8 quantization (requires representative data):
```bash
python export.py --model_path path/to/model.pth --num_classes 5 --quantization int8 \\
                 --representative_data_dir path/to/calibration_images/
```

Export options:
- `--verify`: Verify exported model against PyTorch version
- `--input_size`: Model input size (default: 224)
- `--model_name`: Base name for exported files (default: skin_disease_model)

## Model Architecture

The backend uses EfficientNetV2-B0 as the backbone with a custom classification head:
- Input: 224x224 RGB images
- Backbone: EfficientNetV2-B0 (pre-trained on ImageNet)
- Classifier: Dropout -> Linear(512) -> ReLU -> Dropout -> Linear(num_classes)
- Output: Class logits for disease classification

## Integration with Flutter

1. Export model using the export script (FP16 or INT8 quantization recommended)
2. Copy the generated `.tflite` file to your Flutter app's `assets/models/` directory
3. Add the model to `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/models/skin_disease_model_fp16.tflite
   ```
4. Use the `tflite_flutter` plugin to load and run inference on the model
5. Apply the same preprocessing steps (resizing, normalization) as used during training

## Data Requirements

For best results on Filipino skin tones (Fitzpatrick IV-V):
- Training data should include diverse skin tones, especially Types IV-V
- Images should be well-lit and focused on the lesion/scalp area
- Recommended minimum: 100 images per class for reasonable accuracy
- Data augmentation is applied during training (rotation, flip, color jitter)

## Performance Targets

- Model size: <2 MB after INT8 quantization
- Inference time: <100ms on mid-range mobile devices
- Accuracy: >85% on balanced datasets (depends on data quality and quantity)

## Notes

- The preprocessing algorithms are specifically tuned for dark skin tones
- CLAHE parameters are optimized to enhance lesion boundaries without amplifying noise
- DullRazor effectively removes hair while preserving skin texture in scalp images
- Export scripts include verification to ensure PyTorch and TFLite outputs match