"""
Image Preprocessing Pipeline for Skin/Scalp Lesion Images
Implements CLAHE for contrast enhancement and DullRazor for hair removal
Specifically optimized for Fitzpatrick IV-V skin tones
"""

import cv2
import numpy as np
import os
from typing import Tuple, Optional


def apply_clahe(image: np.ndarray,
                clip_limit: float = 2.0,
                tile_grid_size: Tuple[int, int] = (8, 8)) -> np.ndarray:
    """
    Apply Contrast Limited Adaptive Histogram Equalization (CLAHE)
    to enhance lesion boundaries on dark skin tones.

    Args:
        image: Input image as numpy array (BGR format)
        clip_limit: Threshold for contrast limiting (default: 2.0)
        tile_grid_size: Size of grid for histogram equalization (default: 8x8)

    Returns:
        Enhanced image with improved contrast in lesion areas
    """
    # Convert to LAB color space
    lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
    l_channel, a, b = cv2.split(lab)

    # Apply CLAHE to L channel
    clahe = cv2.createCLAHE(clipLimit=clip_limit, tileGridSize=tile_grid_size)
    l_channel = clahe.apply(l_channel)

    # Merge channels back
    lab = cv2.merge([l_channel, a, b])
    enhanced_image = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)

    return enhanced_image


def dullrazor_hair_removal(image: np.ndarray,
                          kernel_size: int = 15,
                          morph_iterations: int = 1) -> np.ndarray:
    """
    Implement DullRazor algorithm to remove hair occlusions from scalp images.
    Uses black-hat morphology and inpainting to remove hair while preserving skin.

    Args:
        image: Input image as numpy array (BGR format)
        kernel_size: Size of structuring element for morphology (default: 15)
        morph_iterations: Number of morphological operations iterations (default: 1)

    Returns:
        Image with hair removed using inpainting
    """
    # Convert to grayscale for hair detection
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Create structuring element for morphological operations
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (kernel_size, kernel_size))

    # Apply black-hat morphology to detect hair contours
    blackhat = cv2.morphologyEx(gray, cv2.MORPH_BLACKHAT, kernel, iterations=morph_iterations)

    # Apply Gaussian filter to smooth the blackhat result
    bhg = cv2.GaussianBlur(blackhat, (3, 3), 0)

    # Apply Otsu thresholding to create hair mask
    _, mask = cv2.threshold(bhg, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    # Inpaint the image using the mask to remove hair
    # Using Telea algorithm for inpainting
    result = cv2.inpaint(image, mask, 6, cv2.INPAINT_TELEA)

    return result


def preprocess_image(image: np.ndarray,
                    apply_clahe_flag: bool = True,
                    apply_dullrazor_flag: bool = True,
                    clip_limit: float = 2.0,
                    tile_grid_size: Tuple[int, int] = (8, 8),
                    kernel_size: int = 15,
                    morph_iterations: int = 1) -> np.ndarray:
    """
    Main preprocessing pipeline combining CLAHE and DullRazor algorithms.

    Args:
        image: Input image as numpy array (BGR format)
        apply_clahe_flag: Whether to apply CLAHE enhancement (default: True)
        apply_dullrazor_flag: Whether to apply DullRazor hair removal (default: True)
        clip_limit: CLAHE clip limit parameter
        tile_grid_size: CLAHE tile grid size
        kernel_size: DullRazor kernel size for morphology
        morph_iterations: Number of morphological iterations for DullRazor

    Returns:
        Preprocessed image with enhanced contrast and hair removed
    """
    # Make a copy to avoid modifying original
    processed = image.copy()

    # Apply CLAHE for contrast enhancement (especially effective on dark skin)
    if apply_clahe_flag:
        processed = apply_clahe(processed, clip_limit, tile_grid_size)

    # Apply DullRazor for hair removal (particularly useful for scalp images)
    if apply_dullrazor_flag:
        processed = dullrazor_hair_removal(processed, kernel_size, morph_iterations)

    return processed


def preprocess_image_from_file(image_path: str,
                              output_path: Optional[str] = None,
                              **kwargs) -> np.ndarray:
    """
    Load image from file, apply preprocessing, and optionally save result.

    Args:
        image_path: Path to input image file
        output_path: Path to save preprocessed image (if None, doesn't save)
        **kwargs: Additional arguments passed to preprocess_image function

    Returns:
        Preprocessed image as numpy array

    Raises:
        FileNotFoundError: If input image doesn't exist
        ValueError: If image cannot be loaded
    """
    # Load image
    if not os.path.exists(image_path):
        raise FileNotFoundError(f"Image not found: {image_path}")

    image = cv2.imread(image_path)
    if image is None:
        raise ValueError(f"Could not load image: {image_path}")

    # Apply preprocessing
    processed = preprocess_image(image, **kwargs)

    # Save if output path provided
    if output_path is not None:
        # Ensure output directory exists
        output_dir = os.path.dirname(output_path)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir)

        cv2.imwrite(output_path, processed)

    return processed


def preprocess_batch(input_dir: str,
                    output_dir: str,
                    image_extensions: tuple = ('.jpg', '.jpeg', '.png', '.bmp', '.tiff'),
                    **kwargs) -> list:
    """
    Preprocess all images in a directory.

    Args:
        input_dir: Directory containing input images
        output_dir: Directory to save preprocessed images
        image_extensions: Tuple of valid image file extensions
        **kwargs: Additional arguments passed to preprocess_image function

    Returns:
        List of paths to preprocessed images

    Raises:
        FileNotFoundError: If input directory doesn't exist
    """
    if not os.path.exists(input_dir):
        raise FileNotFoundError(f"Input directory not found: {input_dir}")

    # Create output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Get all image files
    image_files = []
    for filename in os.listdir(input_dir):
        if filename.lower().endswith(image_extensions):
            image_files.append(os.path.join(input_dir, filename))

    if not image_files:
        print(f"No image files found in {input_dir} with extensions {image_extensions}")
        return []

    # Process each image
    processed_paths = []
    for image_path in image_files:
        # Generate output filename
        filename = os.path.basename(image_path)
        name, ext = os.path.splitext(filename)
        output_filename = f"{name}_preprocessed{ext}"
        output_path = os.path.join(output_dir, output_filename)

        try:
            preprocess_image_from_file(image_path, output_path, **kwargs)
            processed_paths.append(output_path)
            print(f"Processed: {filename} -> {output_filename}")
        except Exception as e:
            print(f"Error processing {filename}: {str(e)}")

    return processed_paths


if __name__ == "__main__":
    # Example usage
    import argparse

    parser = argparse.ArgumentParser(description='Preprocess skin/scalp lesion images')
    parser.add_argument('--input', type=str, required=True, help='Input image path or directory')
    parser.add_argument('--output', type=str, help='Output image path or directory')
    parser.add_argument('--no-clahe', action='store_true', help='Skip CLAHE enhancement')
    parser.add_argument('--no-dullrazor', action='store_true', help='Skip DullRazor hair removal')
    parser.add_argument('--batch', action='store_true', help='Process directory of images')

    args = parser.parse_args()

    if args.batch:
        # Batch processing
        if not args.output:
            args.output = os.path.join(os.path.dirname(args.input), 'preprocessed')
        preprocess_batch(
            input_dir=args.input,
            output_dir=args.output,
            apply_clahe_flag=not args.no_clahe,
            apply_dullrazor_flag=not args.no_dullrazor
        )
    else:
        # Single image processing
        preprocess_image_from_file(
            image_path=args.input,
            output_path=args.output,
            apply_clahe_flag=not args.no_clahe,
            apply_dullrazor_flag=not args.no_dullrazor
        )
        if args.output:
            print(f"Preprocessed image saved to: {args.output}")
        else:
            print("Image processed (not saved)")