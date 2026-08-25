"""
Model Training & Fine-Tuning for Skin/Scalp Disease Classification
Uses EfficientNetV2-B0 backbone with custom classification head
Specifically designed for multi-class skin and scalp disease classification
"""

import os
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, Dataset
import torchvision.transforms as transforms
from torchvision.datasets import ImageFolder
import timm
from tqdm import tqdm
import numpy as np
from typing import Tuple, Optional, Callable
import argparse
import json
from datetime import datetime


class SkinDiseaseModel(nn.Module):
    """
    Skin disease classification model based on EfficientNetV2-B0 backbone
    with custom classification head for our specific disease classes
    """

    def __init__(self, num_classes: int, backbone: str = 'efficientnetv2_b0',
                 pretrained: bool = True, dropout_rate: float = 0.2):
        """
        Initialize the model

        Args:
            num_classes: Number of disease classes to classify
            backbone: Name of the backbone model from timm (default: efficientnetv2_b0)
            pretrained: Whether to use pretrained weights (default: True)
            dropout_rate: Dropout rate for the classifier head (default: 0.2)
        """
        super(SkinDiseaseModel, self).__init__()

        # Load pre-trained EfficientNetV2-B0 backbone
        self.backbone = timm.create_model(
            backbone,
            pretrained=pretrained,
            num_classes=0,  # Remove the original classifier head
            global_pool=''   # Remove global pooling layer to add our own
        )

        # Get the number of features from the backbone
        with torch.no_grad():
            dummy_input = torch.randn(1, 3, 224, 224)
            features = self.backbone(dummy_input)
            self.num_features = features.shape[1]

        # Global average pooling
        self.global_pool = nn.AdaptiveAvgPool2d(1)

        # Custom classification head
        self.classifier = nn.Sequential(
            nn.Dropout(dropout_rate),
            nn.Linear(self.num_features, 512),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout_rate),
            nn.Linear(512, num_classes)
        )

    def forward(self, x):
        """Forward pass through the network"""
        x = self.backbone(x)
        x = self.global_pool(x)
        x = torch.flatten(x, 1)
        x = self.classifier(x)
        return x

    def unfreeze_backbone(self):
        """Unfreeze backbone parameters for fine-tuning"""
        for param in self.backbone.parameters():
            param.requires_grad = True

    def freeze_backbone(self):
        """Freeze backbone parameters (only train classifier head)"""
        for param in self.backbone.parameters():
            param.requires_grad = False


class FocalLoss(nn.Module):
    """
    Focal Loss for addressing class imbalance in medical datasets
    """

    def __init__(self, alpha: float = 1.0, gamma: float = 2.0, reduction: str = 'mean'):
        """
        Initialize Focal Loss

        Args:
            alpha: Weighting factor for rare class (default: 1.0)
            gamma: Focusing parameter (default: 2.0)
            reduction: Reduction method ('none', 'mean', 'sum') (default: 'mean')
        """
        super(FocalLoss, self).__init__()
        self.alpha = alpha
        self.gamma = gamma
        self.reduction = reduction

    def forward(self, inputs: torch.Tensor, targets: torch.Tensor) -> torch.Tensor:
        """
        Compute focal loss

        Args:
            inputs: Model logits of shape (batch_size, num_classes)
            targets: Ground truth labels of shape (batch_size,)

        Returns:
            Computed focal loss
        """
        ce_loss = nn.CrossEntropyLoss(reduction='none')(inputs, targets)
        pt = torch.exp(-ce_loss)
        focal_loss = self.alpha * (1 - pt) ** self.gamma * ce_loss

        if self.reduction == 'mean':
            return torch.mean(focal_loss)
        elif self.reduction == 'sum':
            return torch.sum(focal_loss)
        else:
            return focal_loss


def get_data_loaders(data_dir: str,
                    batch_size: int = 32,
                    image_size: int = 224,
                    num_workers: int = 4,
                    validation_split: float = 0.2) -> Tuple[DataLoader, DataLoader, dict]:
    """
    Create training and validation data loaders with appropriate transforms

    Args:
        data_dir: Directory containing subdirectories for each class
        batch_size: Batch size for data loaders
        image_size: Size to resize images to (model input size)
        num_workers: Number of worker processes for data loading
        validation_split: Fraction of data to use for validation

    Returns:
        Tuple of (train_loader, val_loader, class_info_dict)
    """
    # Define transforms for training (with augmentation)
    train_transform = transforms.Compose([
        transforms.Resize((image_size + 32, image_size + 32)),  # Slightly larger for random crop
        transforms.RandomResizedCrop(image_size),
        transforms.RandomHorizontalFlip(p=0.5),
        transforms.RandomVerticalFlip(p=0.1),
        transforms.RandomRotation(degrees=15),
        transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406],
                           std=[0.229, 0.224, 0.225])
    ])

    # Define transforms for validation/testing (no augmentation)
    val_transform = transforms.Compose([
        transforms.Resize((image_size, image_size)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406],
                           std=[0.229, 0.224, 0.225])
    ])

    # Load dataset
    full_dataset = ImageFolder(data_dir, transform=train_transform)

    # Split into train and validation
    val_size = int(len(full_dataset) * validation_split)
    train_size = len(full_dataset) - val_size

    train_dataset, val_dataset = torch.utils.data.random_split(
        full_dataset, [train_size, val_size]
    )

    # Apply validation transforms to validation dataset
    val_dataset.dataset.transform = val_transform

    # Create class info dictionary
    class_to_idx = full_dataset.class_to_idx
    idx_to_class = {v: k for k, v in class_to_idx.items()}
    class_info = {
        'class_to_idx': class_to_idx,
        'idx_to_class': idx_to_class,
        'num_classes': len(full_dataset.classes),
        'classes': full_dataset.classes
    }

    # Create data loaders
    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
        pin_memory=True
    )

    val_loader = DataLoader(
        val_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=True
    )

    return train_loader, val_loader, class_info


def train_model(model: nn.Module,
               train_loader: DataLoader,
               val_loader: DataLoader,
               criterion: nn.Module,
               optimizer: optim.Optimizer,
               scheduler: Optional[optim.lr_scheduler._LRScheduler],
               device: torch.device,
               num_epochs: int,
               early_stopping_patience: int = 10,
               checkpoint_dir: str = './models/checkpoints',
               model_name: str = 'skin_disease_model') -> Tuple[nn.Module, dict]:
    """
    Train the model with validation and early stopping

    Args:
        model: The neural network model to train
        train_loader: DataLoader for training data
        val_loader: DataLoader for validation data
        criterion: Loss function
        optimizer: Optimizer for training
        scheduler: Learning rate scheduler (optional)
        device: Device to train on (CPU or GPU)
        num_epochs: Maximum number of epochs to train
        early_stopping_patience: Number of epochs to wait for improvement before stopping
        checkpoint_dir: Directory to save model checkpoints
        model_name: Base name for saved model files

    Returns:
        Tuple of (trained_model, training_history)
    """
    # Create checkpoint directory if it doesn't exist
    os.makedirs(checkpoint_dir, exist_ok=True)

    # Initialize tracking variables
    best_val_loss = float('inf')
    patience_counter = 0
    training_history = {
        'train_loss': [],
        'val_loss': [],
        'train_acc': [],
        'val_acc': [],
        'learning_rates': []
    }

    # Move model to device
    model = model.to(device)

    # Training loop
    for epoch in range(num_epochs):
        model.train()
        running_loss = 0.0
        correct_train = 0
        total_train = 0

        # Training phase
        train_pbar = tqdm(train_loader, desc=f'Epoch {epoch+1}/{num_epochs} [Train]')
        for inputs, labels in train_pbar:
            inputs, labels = inputs.to(device), labels.to(device)

            # Zero the parameter gradients
            optimizer.zero_grad()

            # Forward pass
            outputs = model(inputs)
            loss = criterion(outputs, labels)

            # Backward pass and optimize
            loss.backward()
            optimizer.step()

            # Statistics
            running_loss += loss.item() * inputs.size(0)
            _, predicted = torch.max(outputs.data, 1)
            total_train += labels.size(0)
            correct_train += (predicted == labels).sum().item()

            # Update progress bar
            train_pbar.set_postfix({
                'loss': loss.item(),
                'acc': 100. * correct_train / total_train
            })

        # Calculate epoch statistics
        epoch_train_loss = running_loss / len(train_loader.dataset)
        epoch_train_acc = correct_train / total_train

        # Validation phase
        model.eval()
        val_loss = 0.0
        correct_val = 0
        total_val = 0

        with torch.no_grad():
            val_pbar = tqdm(val_loader, desc=f'Epoch {epoch+1}/{num_epochs} [Val]')
            for inputs, labels in val_pbar:
                inputs, labels = inputs.to(device), labels.to(device)

                outputs = model(inputs)
                loss = criterion(outputs, labels)

                val_loss += loss.item() * inputs.size(0)
                _, predicted = torch.max(outputs.data, 1)
                total_val += labels.size(0)
                correct_val += (predicted == labels).sum().item()

                val_pbar.set_postfix({
                    'loss': loss.item(),
                    'acc': 100. * correct_val / total_val
                })

        epoch_val_loss = val_loss / len(val_loader.dataset)
        epoch_val_acc = correct_val / total_val

        # Update learning rate scheduler
        if scheduler is not None:
            scheduler.step(epoch_val_loss)

        # Record training history
        current_lr = optimizer.param_groups[0]['lr']
        training_history['train_loss'].append(epoch_train_loss)
        training_history['val_loss'].append(epoch_val_loss)
        training_history['train_acc'].append(epoch_train_acc)
        training_history['val_acc'].append(epoch_val_acc)
        training_history['learning_rates'].append(current_lr)

        # Print epoch summary
        print(f'Epoch {epoch+1}/{num_epochs}: '
              f'Train Loss: {epoch_train_loss:.4f}, Train Acc: {epoch_train_acc:.4f}, '
              f'Val Loss: {epoch_val_loss:.4f}, Val Acc: {epoch_val_acc:.4f}, '
              f'LR: {current_lr:.2e}')

        # Checkpoint saving
        if epoch_val_loss < best_val_loss:
            best_val_loss = epoch_val_loss
            patience_counter = 0

            # Save best model
            checkpoint_path = os.path.join(
                checkpoint_dir, f'{model_name}_best.pth'
            )
            torch.save({
                'epoch': epoch,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'scheduler_state_dict': scheduler.state_dict() if scheduler else None,
                'val_loss': epoch_val_loss,
                'val_acc': epoch_val_acc,
                'training_history': training_history
            }, checkpoint_path)
            print(f'  -> Saved best model to {checkpoint_path}')
        else:
            patience_counter += 1
            print(f'  -> No improvement for {patience_counter} epochs')

            # Early stopping
            if patience_counter >= early_stopping_patience:
                print(f'Early stopping triggered after {epoch+1} epochs')
                break

    # Load best model for return
    best_model_path = os.path.join(checkpoint_dir, f'{model_name}_best.pth')
    if os.path.exists(best_model_path):
        checkpoint = torch.load(best_model_path, map_location=device)
        model.load_state_dict(checkpoint['model_state_dict'])
        print(f'Loaded best model from epoch {checkpoint["epoch"]+1} with '
              f'val loss: {checkpoint["val_loss"]:.4f}')

    return model, training_history


def main():
    """Main function for training script"""
    parser = argparse.ArgumentParser(description='Train skin disease classification model')
    parser.add_argument('--data_dir', type=str, required=True,
                       help='Directory containing training data (subdirs per class)')
    parser.add_argument('--batch_size', type=int, default=32,
                       help='Batch size for training (default: 32)')
    parser.add_argument('--image_size', type=int, default=224,
                       help='Input image size for model (default: 224)')
    parser.add_argument('--num_epochs', type=int, default=50,
                       help='Number of training epochs (default: 50)')
    parser.add_argument('--learning_rate', type=float, default=0.001,
                       help='Initial learning rate (default: 0.001)')
    parser.add_argument('--weight_decay', type=float, default=1e-4,
                       help='Weight decay for optimizer (default: 1e-4)')
    parser.add_argument('--validation_split', type=float, default=0.2,
                       help='Fraction of data for validation (default: 0.2)')
    parser.add_argument('--early_stopping_patience', type=int, default=10,
                       help='Early stopping patience (default: 10)')
    parser.add_argument('--use_focal_loss', action='store_true',
                       help='Use Focal Loss instead of CrossEntropyLoss')
    parser.add_argument('--focal_alpha', type=float, default=1.0,
                       help='Alpha parameter for Focal Loss (default: 1.0)')
    parser.add_argument('--focal_gamma', type=float, default=2.0,
                       help='Gamma parameter for Focal Loss (default: 2.0)')
    parser.add_argument('--unfreeze_epoch', type=int, default=10,
                       help='Epoch to unfreeze backbone for fine-tuning (default: 10)')
    parser.add_argument('--checkpoint_dir', type=str, default='./models/checkpoints',
                       help='Directory to save checkpoints (default: ./models/checkpoints)')
    parser.add_argument('--model_name', type=str, default='skin_disease_model',
                       help='Base name for saved models (default: skin_disease_model)')
    parser.add_argument('--num_workers', type=int, default=4,
                       help='Number of data loading workers (default: 4)')
    parser.add_argument('--seed', type=int, default=42,
                       help='Random seed for reproducibility (default: 42)')
    parser.add_argument('--device', type=str, default='auto',
                       help='Device to use (cuda/cpu/auto, default: auto)')

    args = parser.parse_args()

    # Set random seeds for reproducibility
    torch.manual_seed(args.seed)
    np.random.seed(args.seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed(args.seed)

    # Determine device
    if args.device == 'auto':
        device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    else:
        device = torch.device(args.device)

    print(f'Using device: {device}')
    print(f'Training parameters:')
    print(f'  Data directory: {args.data_dir}')
    print(f'  Batch size: {args.batch_size}')
    print(f'  Image size: {args.image_size}')
    print(f'  Epochs: {args.num_epochs}')
    print(f'  Learning rate: {args.learning_rate}')
    print(f'  Validation split: {args.validation_split}')

    # Load data
    print('\nLoading data...')
    train_loader, val_loader, class_info = get_data_loaders(
        data_dir=args.data_dir,
        batch_size=args.batch_size,
        image_size=args.image_size,
        num_workers=args.num_workers,
        validation_split=args.validation_split
    )

    print(f'Found {class_info["num_classes"]} classes: {class_info["classes"]}')
    print(f'Training samples: {len(train_loader.dataset)}')
    print(f'Validation samples: {len(val_loader.dataset)}')

    # Save class info for later use
    os.makedirs(args.checkpoint_dir, exist_ok=True)
    class_info_path = os.path.join(args.checkpoint_dir, 'class_info.json')
    with open(class_info_path, 'w') as f:
        json.dump(class_info, f, indent=2)
    print(f'Saved class info to {class_info_path}')

    # Create model
    print('\nCreating model...')
    model = SkinDiseaseModel(
        num_classes=class_info['num_classes'],
        backbone='efficientnetv2_b0',
        pretrained=True,
        dropout_rate=0.2
    )

    # Initially freeze backbone (only train classifier head)
    model.freeze_backbone()
    print('Backbone frozen - training classifier head only initially')

    # Define loss function
    if args.use_focal_loss:
        criterion = FocalLoss(alpha=args.focal_alpha, gamma=args.focal_gamma)
        print(f'Using Focal Loss (alpha={args.focal_alpha}, gamma={args.focal_gamma})')
    else:
        criterion = nn.CrossEntropyLoss()
        print('Using CrossEntropyLoss')

    # Define optimizer
    optimizer = optim.AdamW(
        model.parameters(),
        lr=args.learning_rate,
        weight_decay=args.weight_decay
    )

    # Define learning rate scheduler
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(
        optimizer,
        mode='min',
        factor=0.5,
        patience=5,
        verbose=True
    )

    # Train model
    print('\nStarting training...')
    trained_model, training_history = train_model(
        model=model,
        train_loader=train_loader,
        val_loader=val_loader,
        criterion=criterion,
        optimizer=optimizer,
        scheduler=scheduler,
        device=device,
        num_epochs=args.num_epochs,
        early_stopping_patience=args.early_stopping_patience,
        checkpoint_dir=args.checkpoint_dir,
        model_name=args.model_name
    )

    # Save training history
    history_path = os.path.join(args.checkpoint_dir, f'{args.model_name}_history.json')
    with open(history_path, 'w') as f:
        json.dump(training_history, f, indent=2)
    print(f'\nTraining history saved to {history_path}')

    # Save final model
    final_model_path = os.path.join(args.checkpoint_dir, f'{args.model_name}_final.pth')
    torch.save({
        'model_state_dict': trained_model.state_dict(),
        'class_info': class_info,
        'training_history': training_history
    }, final_model_path)
    print(f'Final model saved to {final_model_path}')

    print('\nTraining completed successfully!')


if __name__ == '__main__':
    main()