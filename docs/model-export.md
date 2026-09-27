# Model Export (Colab to Flutter)

The app runs both models on-device with `tflite_flutter`. Export them from the
training notebook, then copy the files into `assets/models/`.

## 1. Export cell (add to the end of the notebook)

```python
from ultralytics import YOLO
import tensorflow as tf, shutil

ROOT = "/content/drive/MyDrive/CornLeafTraining/"
YOLO_PT = ROOT + "Final_Data4/YOLOv8_Training10/yolov8s_cornleaf_training_experiment1/weights/best.pt"
EFFNET = ROOT + "efficientnetb0_finetuned_best.keras"

# YOLOv8 to TFLite; imgsz must match the training imgsz.
yolo_dir = YOLO(YOLO_PT).export(format="tflite", imgsz=640, half=True)
shutil.copy(f"{yolo_dir}/best_float16.tflite", ROOT + "yolov8_leaf.tflite")

# EfficientNet-B0 to float16 TFLite; input stays raw 0-255 RGB.
conv = tf.lite.TFLiteConverter.from_keras_model(tf.keras.models.load_model(EFFNET))
conv.optimizations = [tf.lite.Optimize.DEFAULT]
conv.target_spec.supported_types = [tf.float16]
open(ROOT + "efficientnet_b0.tflite", "wb").write(conv.convert())
```

If `export` returns a file path instead of a folder, copy that
`best_float16.tflite` directly.

## 2. Parity check (same notebook)

```python
import numpy as np
interp = tf.lite.Interpreter(ROOT + "efficientnet_b0.tflite")
interp.allocate_tensors()
x = np.expand_dims(np.array(preprocess_leaf(cropped_leaves[0])), 0).astype(np.float32)
interp.set_tensor(interp.get_input_details()[0]["index"], x)
interp.invoke()
print(interp.get_tensor(interp.get_output_details()[0]["index"]))
print(best_model.predict(x, verbose=0))
```

Both rows should match to about two decimal places.

## 3. Add to the app

- `assets/models/yolov8_leaf.tflite`
- `assets/models/efficientnet_b0.tflite`

Then run `flutter pub get` and `flutter run`.

## Pipeline notes (must match training)

- YOLO input: letterboxed to 640, gray (114) padding, RGB scaled to 0-1.
- Leaf confidence threshold is 0.45 (`_leafConfThreshold`), NMS IoU 0.45.
- Classifier input: crop, keep aspect ratio, pad with median edge color to
  224x224, raw 0-255 floats (EfficientNet normalizes internally).
- Class order: Healthy, Nitrogen, Phosphorus, Potassium.
