# Classifier confidence calibration

The fine-tuned EfficientNet-B0 reports 99-100% on almost every leaf, while its
test accuracy is 89.63% and Potassium recall is 62.5% (notebook cells 42-43).
The score is not wrong code - a softmax trained with plain cross-entropy is
simply pushed to 0 or 1. Temperature scaling fixes the reported number without
retraining or changing which class wins.

## 1. Fit the temperature in Colab

Run after cell 42 (the best fine-tuned model and `val_dataset` must be loaded).
Fit on validation, never on test.

```python
import numpy as np, tensorflow as tf
from scipy.optimize import minimize_scalar

y_val = np.concatenate([y.numpy() for _, y in val_dataset])
p_val = best_model.predict(val_dataset, verbose=0)

# The model ends in softmax, so log(p) recovers the logits up to a constant,
# which softmax ignores.
logits = np.log(np.clip(p_val, 1e-12, 1.0))

def nll(T):
    z = logits / T
    z -= z.max(axis=1, keepdims=True)
    p = np.exp(z) / np.exp(z).sum(axis=1, keepdims=True)
    return -np.mean(np.log(p[np.arange(len(y_val)), y_val] + 1e-12))

T = minimize_scalar(nll, bounds=(0.5, 10.0), method="bounded").x
print(f"Temperature T = {T:.3f}")
```

## 2. Check that it helped (expected calibration error)

```python
def ece(probs, labels, bins=10):
    conf, pred = probs.max(axis=1), probs.argmax(axis=1)
    correct = (pred == labels).astype(float)
    edges, total = np.linspace(0, 1, bins + 1), 0.0
    for lo, hi in zip(edges[:-1], edges[1:]):
        m = (conf > lo) & (conf <= hi)
        if m.sum():
            total += m.mean() * abs(correct[m].mean() - conf[m].mean())
    return total

def scale(probs, T):
    z = np.log(np.clip(probs, 1e-12, 1.0)) / T
    z -= z.max(axis=1, keepdims=True)
    return np.exp(z) / np.exp(z).sum(axis=1, keepdims=True)

y_test = np.concatenate([y.numpy() for _, y in test_dataset])
p_test = best_model.predict(test_dataset, verbose=0)

print(f"Accuracy          : {(p_test.argmax(1) == y_test).mean():.4f}")
print(f"Mean confidence   : {p_test.max(1).mean():.4f}  -> "
      f"{scale(p_test, T).max(1).mean():.4f}")
print(f"ECE               : {ece(p_test, y_test):.4f}  -> "
      f"{ece(scale(p_test, T), y_test):.4f}")
```

Accuracy and the confusion matrix do not change - temperature scaling divides
every logit by the same number, so the winning class is the same. Only the
reported confidence moves, toward the accuracy the model actually has. Report
both ECE values in the paper.

## 3. Put T in the app

Set `_temperature` in `lib/services/detection_service.dart` to the fitted
value. At 1.0 the raw scores are used unchanged.

## Confidence bands in the UI

`lib/core/confidence.dart` maps the calibrated score to what the user sees:

- 85% and above: High confidence
- 65 to 85%: Medium confidence
- below 65%: Low confidence, and the result screen shows a retake notice

Retune these thresholds after fitting T, using the test set: pick the cut-off
where accuracy inside the band stops being acceptable for a fertilizer
recommendation.
