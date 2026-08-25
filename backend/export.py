"""
Model Quantization & Export for TensorFlow Lite
Converts trained PyTorch model to TensorFlow Lite with FP16/INT8 quantization
Optimized for Flutter tflite_flutter offline inference
"""

import os
import torch
import torch.nn as nn
import numpy as np
import tensorflow as tf
from typing import Tuple, Optional, Callable, Generator
import argparse
import json
from PIL import Image
import cv2


def load_pytorch_model(model_path: str,
                      num_classes: int,
                      device: str = 'cpu') -> nn.Module:
    """
    Load a trained PyTorch model from checkpoint

    Args:
        model_path: Path to the trained model checkpoint (.pth file)
        num_classes: Number of output classes
        device: Device to load model on ('cpu' or 'cuda')

    Returns:
        Loaded PyTorch model in evaluation mode
    """
    # Check if file exists
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model file not found: {model_path}")

    # Load checkpoint
    checkpoint = torch.load(model_path, map_location=device)

    # Extract model state dict and class info if available
    if 'model_state_dict' in checkpoint:
        model_state_dict = checkpoint['model_state_dict']
        class_info = checkpoint.get('class_info', None)
    else:
        # Assume the checkpoint is just the state dict
        model_state_dict = checkpoint
        class_info = None

    # Create model instance
    from train import SkinDiseaseModel  # Import from train.py
    model = SkinDiseaseModel(
        num_classes=num_classes,
        backbone='efficientnetv2_b0',
        pretrained=False,  # We're loading our own weights
        dropout_rate=0.2
    )

    # Load state dict
    model.load_state_dict(model_state_dict)
    model.to(device)
    model.eval()  # Set to evaluation mode

    print(f'Loaded PyTorch model from {model_path}')
    if class_info:
        print(f'Model classes: {class_info.get("classes", "Unknown")}')

    return model


def convert_pytorch_to_tflite(pytorch_model: nn.Module,
                             input_shape: Tuple[int, int, int, int] = (1, 3, 224, 224)) -> bytes:
    """
    Convert PyTorch model to TensorFlow Lite format

    Args:
        pytorch_model: Trained PyTorch model in evaluation mode
        input_shape: Input tensor shape (batch, channels, height, width)

    Returns:
        TensorFlow Lite model as bytes
    """
    # Set model to evaluation mode
    pytorch_model.eval()

    # Create example input for tracing
    example_input = torch.randn(input_shape)

    # Trace the PyTorch model
    traced_model = torch.jit.trace(pytorch_model, example_input)

    # Convert to TensorFlow Lite
    converter = tf.lite.TFLiteConverter.from_concrete_functions(
        [traced_model.get_concrete_function()]
    )

    # Optional: Optimize for size/latency
    converter.optimizations = [tf.lite.Optimize.DEFAULT]

    # Convert model
    tflite_model = converter.convert()

    print(f'Converted PyTorch model to TensorFlow Lite')
    print(f'Input shape: {input_shape}')
    print(f'Model size: {len(tflite_model) / 1024:.2f} KB')

    return tflite_model


def quantize_fp16(tflite_model_bytes: bytes) -> bytes:
    """
    Apply FP16 quantization to TensorFlow Lite model

    Args:
        tflite_model_bytes: Original TensorFlow Lite model as bytes

    Returns:
        FP16 quantized TensorFlow Lite model as bytes
    """
    converter = tf.lite.TFLiteConverter.from_model_content(tflite_model_bytes)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]

    tflite_model_fp16 = converter.convert()

    print(f'FP16 quantization completed')
    print(f'Original size: {len(tflite_model_bytes) / 1024:.2f} KB')
    print(f'FP16 size: {len(tflite_model_fp16) / 1024:.2f} KB')
    print(f'Size reduction: {(1 - len(tflite_model_fp16) / len(tflite_model_bytes)) * 100:.1f}%')

    return tflite_model_fp16


def quantize_int8(tflite_model_bytes: bytes,
                 representative_data_gen: Callable[[], Generator[np.ndarray, None, None]]) -> bytes:
    """
    Apply INT8 quantization to TensorFlow Lite model using representative dataset

    Args:
        tflite_model_bytes: Original TensorFlow Lite model as bytes
        representative_data_gen: Generator function yielding batches of input data for calibration

    Returns:
        INT8 quantized TensorFlow Lite model as bytes
    """
    converter = tf.lite.TFLiteConverter.from_model_content(tflite_model_bytes)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_data_gen
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS_INT8
    ]
    converter.inference_input_type = tf.uint8
    converter.inference_output_type = tf.uint8

    tflite_model_int8 = converter.convert()

    print(f'INT8 quantization completed')
    print(f'Original size: {len(tflite_model_bytes) / 1024:.2f} KB')
    print(f'INT8 size: {len(tflite_model_int8) / 1024:.2f} KB')
    print(f'Size reduction: {(1 - len(tflite_model_int8) / len(tflite_model_bytes)) * 100:.1f}%')

    return tflite_model_int8


def create_representative_data_generator(preprocessed_dir: str,
                                       image_size: int = 224,
                                       batch_size: int = 1,
                                       max_batches: int = 100) -> Callable[[], Generator[np.ndarray, None, None]]:
    """
    Create a representative data generator for INT8 quantization calibration

    Args:
        preprocessed_dir: Directory containing preprocessed images for calibration
        image_size: Size to resize images to
        batch_size: Batch size for calibration (typically 1 for INT8)
        max_batches: Maximum number of batches to generate

    Returns:
        Generator function that yields batches of preprocessed images
    """
    def representative_data_gen():
        # Get list of image files
        image_extensions = ('.jpg', '.jpeg', '.png', '.bmp', '.tiff')
        image_files = []

        for root, dirs, files in os.walk(preprocessed_dir):
            for file in files:
                if file.lower().endswith(image_extensions):
                    image_files.append(os.path.join(root, file))

        if not image_files:
            raise ValueError(f"No image files found in {preprocessed_dir}")

        # Limit number of batches
        image_files = image_files[:max_batches * batch_size]

        batch_count = 0
        for i in range(0, len(image_files), batch_size):
            if batch_count >= max_batches:
                break

            batch_files = image_files[i:i+batch_size]
            batch_images = []

            for img_path in batch_files:
                try:
                    # Load and preprocess image
                    img = cv2.imread(img_path)
                    if img is None:
                        continue

                    # Resize to model input size
                    img = cv2.resize(img, (image_size, image_size))

                    # Convert BGR to RGB (TensorFlow expects RGB)
                    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

                    # Normalize to [0, 1] range
                    img = img.astype(np.float32) / 255.0

                    # Apply ImageNet normalization (same as used in training)
                    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
                    std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
                    img = (img - mean) / std

                    # Transpose to CHW format (PyTorch format) then add batch dimension
                    img = np.transpose(img, (2, 0, 1))  # HWC to CHW
                    img = np.expand_dims(img, axis=0)   # Add batch dimension

                    batch_images.append(img)
                except Exception as e:
                    print(f"Warning: Could not process {img_path}: {e}")
                    continue

            if batch_images:
                # Concatenate batch
                batch = np.concatenate(batch_images, axis=0)
                yield batch.astype(np.float32)
                batch_count += 1

    return representative_data_gen


def verify_tflite_model(tflite_model_path: str,
                       pytorch_model: nn.Module,
                       test_input: np.ndarray,
                       device: str = 'cpu') -> Tuple[bool, float]:
    """
    Verify that TensorFlow Lite model produces similar outputs to PyTorch model

    Args:
        tflite_model_path: Path to the TensorFlow Lite model file
        pytorch_model: Original PyTorch model for comparison
        test_input: Test input tensor (numpy array) with shape (1, C, H, W)
        device: Device to run PyTorch model on

    Returns:
        Tuple of (is_valid, max_difference) where is_valid is True if difference < threshold
    """
    # Load TFLite model and allocate tensors
    interpreter = tf.lite.Interpreter(model_path=tflite_model_path)
    interpreter.allocate_tensors()

    # Get input and output tensors
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Run TensorFlow Lite inference
    interpreter.set_tensor(input_details[0]['index'], test_input.astype(input_details[0]['dtype']))
    interpreter.invoke()
    tflite_output = interpreter.get_tensor(output_details[0]['index'])

    # Run PyTorch inference
    pytorch_model.eval()
    with torch.no_grad():
        pytorch_input = torch.from_numpy(test_input).to(device)
        pytorch_output = pytorch_model(pytorch_input)
        pytorch_output = pytorch_output.cpu().numpy()

    # Calculate difference
    if tflite_output.shape != pytorch_output.shape:
        # Handle potential shape differences due to quantization
        # Usually TFLite output might have different shape if uint8
        try:
            # Reshape if needed
            if tflite_output.size == pytorch_output.size:
                tflite_output = tflite_output.reshape(pytorch_output.shape)
            else:
                print(f"Shape mismatch: TFLite {tflite_output.shape} vs PyTorch {pytorch_output.shape}")
                return False, float('inf')
        except:
            print(f"Shape mismatch: TFLite {tflite_output.shape} vs PyTorch {pytorch_output.shape}")
            return False, float('inf')

    # Calculate absolute difference
    abs_diff = np.abs(tflite_output.astype(np.float32) - pytorch_output)
    max_diff = np.max(abs_diff)
    mean_diff = np.mean(abs_diff)

    print(f'Verification results:')
    print(f'  Max difference: {max_diff:.6f}')
    print(f'  Mean difference: {mean_diff:.6f}')

    # Threshold for acceptable difference (adjust based on quantization type)
    threshold = 0.1  # Relaxed threshold for INT8, tighter for FP16
    is_valid = max_diff < threshold

    if is_valid:
        print(f'  -> Model verification PASSED (diff < {threshold})')
    else:
        print(f'  -> Model verification FAILED (diff >= {threshold})')

    return is_valid, max_diff


def main():
    """Main function for export script"""
    parser = argparse.ArgumentParser(description='Export PyTorch model to TensorFlow Lite')
    parser.add_argument('--model_path', type=str, required=True,
                       help='Path to trained PyTorch model checkpoint (.pth file)')
    parser.add_argument('--output_dir', type=str, default='./models/exported',
                       help='Directory to save exported TFLite models (default: ./models/exported)')
    parser.add_argument('--num_classes', type=int, required=True,
                       help='Number of output classes')
    parser.add_argument('--quantization', type=str, choices=['none', 'fp16', 'int8'], default='fp16',
                       help='Quantization type: none, fp16, or int8 (default: fp16)')
    parser.add_argument('--input_size', type=int, default=224,
                       help='Model input image size (default: 224)')
    parser.add_argument('--representative_data_dir', type=str, default=None,
                       help='Directory with representative images for INT8 calibration (required for int8)')
    parser.add_argument('--max_calibration_batches', type=int, default=100,
                       help='Maximum number of batches for INT8 calibration (default: 100)')
    parser.add_argument('--verify', action='store_true',
                       help='Verify exported model against PyTorch model')
    parser.add_argument('--device', type=str, default='auto',
                       help='Device to use for PyTorch model (cuda/cpu/auto, default: auto)')
    parser.add_argument('--model_name', type=str, default='skin_disease_model',
                       help='Base name for exported models (default: skin_disease_model)')

    args = parser.parse_args()

    # Validate arguments
    if args.quantization == 'int8' and not args.representative_data_dir:
        parser.error("--representative_data_dir is required for INT8 quantization")

    if not os.path.exists(args.model_path):
        parser.error(f"Model file not found: {args.model_path}")

    if args.quantization == 'int8' and not os.path.exists(args.representative_data_dir):
        parser.error(f"Representative data directory not found: {args.representative_data_dir}")

    # Determine device
    if args.device == 'auto':
        device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    else:
        device = torch.device(args.device)

    print(f'Using device: {device}')
    print(f'Export settings:')
    print(f'  Model path: {args.model_path}')
    print(f'  Output directory: {args.output_dir}')
    print(f'  Quantization: {args.quantization}')
    print(f'  Input size: {args.input_size}')

    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)

    # Load PyTorch model
    print('\nLoading PyTorch model...')
    pytorch_model = load_pytorch_model(
        model_path=args.model_path,
        num_classes=args.num_classes,
        device=device
    )

    # Convert to TensorFlow Lite
    print('\nConverting to TensorFlow Lite...')
    input_shape = (1, 3, args.input_size, args.input_size)
    tflite_model_bytes = convert_pytorch_to_tflite(pytorch_model, input_shape)

    # Apply quantization if requested
    if args.quantization == 'fp16':
        print('\nApplying FP16 quantization...')
        tflite_model_bytes = quantize_fp16(tflite_model_bytes)
        output_suffix = '_fp16'
    elif args.quantization == 'int8':
        print('\nApplying INT8 quantization...')
        # Create representative data generator
        rep_data_gen = create_representative_data_generator(
            preprocessed_dir=args.representative_data_dir,
            image_size=args.input_size,
            max_batches=args.max_calibration_batches
        )
        tflite_model_bytes = quantize_int8(tflite_model_bytes, rep_data_gen)
        output_suffix = '_int8'
    else:
        output_suffix = ''

    # Save TensorFlow Lite model
    model_filename = f'{args.model_name}{output_suffix}.tflite'
    output_path = os.path.join(args.output_dir, model_filename)

    with open(output_path, 'wb') as f:
        f.write(tflite_model_bytes)

    print(f'\nSaved TensorFlow Lite model to: {output_path}')
    print(f'Model size: {len(tflite_model_bytes) / 1024:.2f} KB')

    # Verify model if requested
    if args.verify:
        print('\nVerifying exported model...')
        # Create test input (random noise for verification)
        test_input = np.random.randn(1, 3, args.input_size, args.input_size).astype(np.float32)

        # Apply same normalization as used in training
        mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
        std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
        test_input = (test_input - mean.reshape(1, 3, 1, 1)) / std.reshape(1, 3, 1, 1)

        is_valid, max_diff = verify_tflite_model(
            tflite_model_path=output_path,
            pytorch_model=pytorch_model,
            test_input=test_input,
            device=device
        )

        if is_valid:
            print('��✓ Model verification successful')
        else:
            print('��✗ Model verification failed - consider checking quantization settings')

    # Save model metadata
    metadata = {
        'model_name': args.model_name,
        'quantization': args.quantization,
        'input_size': args.input_size,
        'num_classes': args.num_classes,
        'model_size_kb': len(tflite_model_bytes) / 1024,
        'pytorch_source': args.model_path,
        'export_date': str(np.datetime64('now')),
        'framework': 'TensorFlow Lite',
        'compatible_with': ['tflite_flutter']
    }

    metadata_path = os.path.join(args.output_dir, f'{args.model_name}{output_suffix}_metadata.json')
    with open(metadata_path, 'w') as f:
        json.dump(metadata, f, indent=2)

    print(f'Metadata saved to: {metadata_path}')

    print('\nExport completed successfully!')
    print(f'To use in Flutter:')
    print(f'  1. Copy {output_path} to flutter_app/assets/models/')
    print(f'  2. Add to pubspec.yaml under assets:')
    print(f'     - assets/models/{model_filename}')
    print(f'  3. Load in Flutter using tflite_flutter plugin')


if __name__ == '__main__':
    main()