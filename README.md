# What does this script do?

This script sets up a full NVIDIA DeepStream + YOLO (Ultralytics YOLO11) environment, mainly targeting NVIDIA Jetson devices or systems running DeepStream SDK 7.1.

### Requirement: 
- Linux OS
- Jetson Orin (or Nvidia board)
- Cuda 12.6

In simple terms, it:

1. Builds and installs GLib 2.76.6 from source

Required for compatibility with DeepStream and GStreamer components.

2. Installs GStreamer and multimedia dependencies

Needed for video pipelines, RTSP, decoding/encoding, and DeepStream plugins.

3. Updates DeepStream RTP manager

Fixes or updates RTP streaming functionality inside DeepStream.

4. Builds and installs librdkafka (Kafka support)

Enables Kafka messaging support for DeepStream applications.

5. Sets up Python ML environment

Installs PyTorch, TorchVision, NumPy (pinned versions), OpenCV, ONNX, etc.

6. Ensures compatibility with DeepStream and TensorRT.

Installs Ultralytics YOLO

7. Used to export YOLO models (YOLO11) to ONNX format.

Exports YOLO11 model to ONNX

8. Converts yolo11s.pt → yolo11s.pt.onnx for DeepStream inference.

Builds DeepStream YOLO custom inference plugin

9. Compiles the TensorRT-based YOLO parser and inference engine.

Installs NVIDIA JetPack & system components

Ensures CUDA, TensorRT, drivers, and kernel are correctly installed.

## End Result

After running this script, you have:

✅ DeepStream 7.1 ready

✅ YOLO11 ONNX model exported

✅ Custom DeepStream YOLO inference plugin built

✅ System ready to run YOLO inference pipelines in DeepStream
