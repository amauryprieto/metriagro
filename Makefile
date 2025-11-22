# Simple ML pipeline Makefile
# Usage examples:
#   make data-split
#   make train EPOCHS=100 IMGSZ=640 BATCH=16 NAME=cacao_yolov9
#   make export NAME=cacao_yolov9
#   make package NAME=cacao_yolov9

PY ?= python
ML_DIR := ml
DATA_YAML ?= $(ML_DIR)/data/data.yaml
NAME ?= cacao_yolov9
EPOCHS ?= 100
IMGSZ ?= 640
BATCH ?= 16

.PHONY: help data-validate data-split train export eval package clean

help:
	@echo "Targets:"
	@echo "  make data-validate              # Quick dataset sanity checks"
	@echo "  make data-split                 # Build YOLOv9 dataset structure from data-raw/"
	@echo "  make train [EPOCHS IMGSZ BATCH NAME]  # Train YOLOv9"
	@echo "  make export [NAME]              # Export best.pt to ONNX and TFLite (best-effort)"
	@echo "  make eval [NAME]                # Placeholder for evaluation/reporting"
	@echo "  make package [NAME]             # Package artifacts into artifacts/"
	@echo "  make clean                      # Remove runs and temporary artifacts"

data-validate:
	@echo "[validate] Checking dataset layout..."
	@[ -f $(DATA_YAML) ] && echo "Found: $(DATA_YAML)" || (echo "Missing: $(DATA_YAML). Run 'make data-split' first." && exit 1)
	@echo "[validate] OK"

data-split:
	@echo "[data] Building YOLOv9 dataset structure from data-raw/..."
	$(PY) $(ML_DIR)/convert_to_yolov9.py
	@echo "[data] data.yaml generated at: $(DATA_YAML)"

train: data-validate
	@echo "[train] Starting training with NAME=$(NAME) EPOCHS=$(EPOCHS) IMGSZ=$(IMGSZ) BATCH=$(BATCH)"
	$(PY) $(ML_DIR)/train_yolov9.py \
	  --data $(DATA_YAML) \
	  --epochs $(EPOCHS) \
	  --imgsz $(IMGSZ) \
	  --batch $(BATCH) \
	  --name $(NAME)

export: data-validate
	@echo "[export] Exporting runs_yolov9/$(NAME)/weights/best.pt to ONNX and TFLite (best-effort)"
	@BEST_WEIGHTS="$(ML_DIR)/runs_yolov9/$(NAME)/weights/best.pt"; \
	if [ ! -f $$BEST_WEIGHTS ]; then \
	  echo "Missing $$BEST_WEIGHTS. Train first: make train NAME=$(NAME)"; exit 1; \
	fi; \
	$(PY) - <<'PY'
from ultralytics import YOLO
from pathlib import Path
import sys

best = Path("$(ML_DIR)/runs_yolov9/$(NAME)/weights/best.pt").resolve()
print(f"[export] Loading {best}")
model = YOLO(str(best))

try:
    print("[export] ONNX...")
    model.export(format='onnx')
    print("[export] ONNX: OK")
except Exception as e:
    print(f"[export] ONNX failed: {e}")

try:
    print("[export] TFLite...")
    model.export(format='tflite')
    print("[export] TFLite: OK")
except Exception as e:
    print(f"[export] TFLite failed: {e}")
PY

eval: data-validate
	@echo "[eval] Summarizing metrics for $(NAME)"
	$(PY) ml/eval_metrics.py --name $(NAME) --runs-dir ml/runs_yolov9 --out-dir artifacts

package:
	@echo "[package] Collecting artifacts for $(NAME)"
	@mkdir -p artifacts/$(NAME)
	@cp -R $(ML_DIR)/runs_yolov9/$(NAME) artifacts/ 2>/dev/null || true
	@echo "Artifacts available at artifacts/$(NAME)"

clean:
	@echo "[clean] Removing runs and artifacts"
	rm -rf $(ML_DIR)/runs_yolov9 artifacts
	@echo "[clean] Done"
