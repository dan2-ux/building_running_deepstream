#!/bin/bash

# =========================================================
# DeepStream + YOLO11 Setup Script
# This script installs dependencies and sets up YOLO11
# for NVIDIA DeepStream on Jetson/Linux
# =========================================================

echo "Starting DeepStream + YOLO11 setup..."

# ---------------------------
# Update system
# ---------------------------
sudo apt update

# ---------------------------
# Install Python build tools
# ---------------------------
pip3 install --upgrade pip setuptools wheel
pip3 install meson ninja   # build tools for compiling libraries

# ---------------------------
# Install GLib (required for GStreamer/DeepStream)
# ---------------------------
git clone https://github.com/GNOME/glib.git
cd glib || exit
git checkout 2.76.6        # use compatible version
meson build --prefix=/usr
ninja -C build/
cd build/
sudo ninja install         # install GLib system-wide
cd ../..

# Verify GLib installation
pkg-config --modversion glib-2.0

# ---------------------------
# Install GStreamer + dependencies
# ---------------------------
sudo apt install -y \
libssl3 libssl-dev \
libgstreamer1.0-0 gstreamer1.0-tools \
gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
gstreamer1.0-libav \
libgstreamer-plugins-base1.0-dev \
libgstrtspserver-1.0-0 \
libjansson4 libyaml-cpp-dev

# ---------------------------
# Update DeepStream RTP manager
# ---------------------------
cd /opt/nvidia/deepstream/deepstream-7.1 || exit
sudo ./update_rtpmanager.sh   # fix streaming components
cd ~

# ---------------------------
# Install librdkafka (Kafka support)
# ---------------------------
git clone https://github.com/confluentinc/librdkafka.git
cd librdkafka || exit
git checkout tags/v2.2.0      # stable version
./configure --enable-ssl
make
sudo make install

# Copy library to DeepStream folder
sudo mkdir -p /opt/nvidia/deepstream/deepstream-7.1/lib
sudo cp /usr/local/lib/librdkafka* /opt/nvidia/deepstream/deepstream-7.1/lib
sudo ldconfig
cd ~

# ---------------------------
# Install Python ML dependencies
# ---------------------------
pip install -U pip
git clone https://github.com/ultralytics/ultralytics
cd ultralytics || exit

# Install YOLO export dependencies
pip install -e ".[export]" onnxslim --use-deprecated=legacy-resolver
pip install onnx --extra-index-url https://pypi.ngc.nvidia.com

# Install compatible versions
pip3 install torch
pip install tqdm
pip uninstall -y opencv-python
pip install opencv-python==4.6.0.66
pip uninstall -y numpy
pip install numpy==1.23.5
pip install torchvision==0.15.2

cd ~

# ---------------------------
# Clone DeepStream-Yolo integration
# ---------------------------
git clone https://github.com/marcoslucianops/DeepStream-Yolo

# Copy export script into ultralytics
cp ~/DeepStream-Yolo/utils/export_yolo11.py ~/ultralytics
cd ultralytics || exit

# ---------------------------
# Download and export YOLO11 model
# ---------------------------
wget https://github.com/ultralytics/assets/releases/download/v8.3.0/yolo11s.pt

# Convert PyTorch model → ONNX format
python3 export_yolo11.py -w yolo11s.pt

# Move model and labels to DeepStream-Yolo
cp yolo11s.pt.onnx labels.txt ~/DeepStream-Yolo
cd ~/DeepStream-Yolo || exit

# ---------------------------
# Build DeepStream YOLO plugin
# ---------------------------
export CUDA_VER=12.6    # set CUDA version (adjust if needed)

make -C nvdsinfer_custom_impl_Yolo clean
make -C nvdsinfer_custom_impl_Yolo

# ---------------------------
# Install NVIDIA JetPack (CUDA, TensorRT, etc.)
# ---------------------------
sudo apt-get install -y nvidia-jetpack nvidia-l4t-bootloader nvidia-l4t-kernel

# ---------------------------
# Update configuration files automatically
# ---------------------------

# Update YOLO config to use ONNX model
CONFIG_FILE="config_infer_primary_yoloV8.txt"
if [ -f "$CONFIG_FILE" ]; then
    sed -i 's|^onnx-file=.*|onnx-file=yolo11s.pt.onnx|' "$CONFIG_FILE"
else
    echo "Warning: $CONFIG_FILE not found"
fi

# Update DeepStream app config to use YOLO config
DEEPSTREAM_CFG="deepstream_app_config.txt"
if [ -f "$DEEPSTREAM_CFG" ]; then
    sed -i '59s|.*|config-file=config_infer_primary_yoloV8.txt|' "$DEEPSTREAM_CFG"
else
    echo "Warning: $DEEPSTREAM_CFG not found"
fi

# ---------------------------
# Done
# ---------------------------
echo "Setup complete! You can now run DeepStream with YOLO11."

# This is the .sh file that will automatically do all the manual tasks below 
# vim config_infer_primary_yoloV8.txt 
# ESC 
#:w = for save 
# :wq = for save and quit 
# :q! = for quit without saving #change to this 
# onnx-file=yolo11s.pt.onnx 
# go into deepstream_app_config.txt 
# change line 59 to # config-file=config_infer_primary_yoloV8.txt