# Card Detection Model

This directory contains the TFLite object detection model and supporting files for
the Poker Hand Suggester's "Scan Table" feature.

## Files

| File | Description |
|------|-------------|
| `card_detection_model.tflite` | TFLite object detection model (placeholder — replace with your trained model) |
| `card_labels.txt` | 52 class labels, one per line, in `rank_suit` format (e.g. `ace_spades`) |

## Model Input / Output

The code in `lib/recognition/card_detector.dart` expects an **SSD-style** TFLite model with the following signature:

| Tensor | Shape | Description |
|--------|-------|-------------|
| Input  | `[1, 320, 320, 3]` float32 (0–1 normalized) | RGB image |
| Output 0 — boxes   | `[1, N, 4]` float32 | Bounding boxes `[top, left, bottom, right]` (0–1 normalized) |
| Output 1 — classes | `[1, N]` float32 | Class index into `card_labels.txt` |
| Output 2 — scores  | `[1, N]` float32 | Confidence scores (0–1) |
| Output 3 — count   | `[1]` float32 | Number of valid detections |

Adjust `_inputSize` and `numDetections` in `card_detector.dart` to match your model.

## Obtaining a Pre-Trained Model

### Option A — Roboflow Universe (Easiest)

1. Go to [Roboflow Universe — Playing Cards](https://universe.roboflow.com/augmented-startups/playing-cards-ow27d)
2. Click **"Train"** → select **YOLOv8n** or **YOLOv5s**
3. After training, click **"Export"** → choose **TFLite** format
4. Download and rename the model file to `card_detection_model.tflite`
5. Replace the placeholder file in this directory

### Option B — Custom Training

1. Collect or download a playing-card image dataset (e.g. from Roboflow, Kaggle, or your own photos)
2. Annotate each card with bounding boxes and one of the 52 labels from `card_labels.txt`
3. Train an SSD MobileNet v2 or EfficientDet-Lite model using TensorFlow / TensorFlow Lite Model Maker
4. Export as `.tflite` and place here

### Option C — Pre-Converted Community Models

Several community-trained card detection TFLite models are available on GitHub, for example:
- [TeogopK/Playing-Cards-Object-Detection](https://github.com/TeogopK/Playing-Cards-Object-Detection)

Download a model and convert to TFLite if not already in that format.

## Replacing the Placeholder

Simply copy your `card_detection_model.tflite` into this directory, replacing the stub file. No code changes are required as long as the model uses the input/output format described above.
