#!/bin/bash

echo "Starting DeepStream + YOLO11 setup..."

# ---------------------------
# Install Python tools
# ---------------------------
pip3 install --upgrade pip setuptools wheel
pip3 install meson ninja

# ---------------------------
# Install GLib 2.76.6
# ---------------------------
git clone https://github.com/GNOME/glib.git
cd glib
git checkout 2.76.6
sudo apt update
sudo apt install -y meson
meson build --prefix=/usr
ninja -C build/
cd build/
sudo ninja install
cd ../..
pkg-config --modversion glib-2.0

# ---------------------------
# Install GStreamer and dependencies
# ---------------------------
sudo apt install -y \
libssl3 libssl-dev libgstreamer1.0-0 gstreamer1.0-tools \
gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
gstreamer1.0-libav libgstreamer-plugins-base1.0-dev libgstrtspserver-1.0-0 \
libjansson4 libyaml-cpp-dev

# ---------------------------
# Update DeepStream RTP manager
# ---------------------------
cd /opt/nvidia/deepstream/deepstream-7.1
sudo ./update_rtpmanager.sh
cd ~ || exit

# ---------------------------
# Install librdkafka 2.2.0
# ---------------------------
sudo git clone https://github.com/confluentinc/librdkafka.git
cd librdkafka
sudo git checkout tags/v2.2.0
sudo ./configure --enable-ssl
sudo make
sudo make install
sudo mkdir -p /opt/nvidia/deepstream/deepstream-7.1/lib
sudo cp /usr/local/lib/librdkafka* /opt/nvidia/deepstream/deepstream-7.1/lib
sudo ldconfig
cd ~ || exit

# ---------------------------
# Python ML setup
# ---------------------------
pip install -U pip
git clone https://github.com/ultralytics/ultralytics
cd ultralytics || exit
pip install -e ".[export]" onnxslim --use-deprecated=legacy-resolver
pip install onnx --extra-index-url https://pypi.ngc.nvidia.com
pip3 install torch
pip install numpy tqdm
pip uninstall -y opencv-python
pip install opencv-python==4.6.0.66
pip uninstall -y numpy
pip install numpy==1.23.5
pip install torchvision==0.15.2
cd ~ || exit

# ---------------------------
# Clone DeepStream-Yolo
# ---------------------------
git clone https://github.com/marcoslucianops/DeepStream-Yolo
cp ~/DeepStream-Yolo/utils/export_yolo11.py ~/ultralytics
cd ultralytics || exit

# Download YOLO11 model
wget https://github.com/ultralytics/assets/releases/download/v8.3.0/yolo11s.pt
python3 export_yolo11.py -w yolo11s.pt
cp yolo11s.pt.onnx labels.txt ~/DeepStream-Yolo
cd ~/DeepStream-Yolo || exit

# ---------------------------
# Build DeepStream YOLO plugin
# ---------------------------
export CUDA_VER=12.6
make -C nvdsinfer_custom_impl_Yolo clean
make -C nvdsinfer_custom_impl_Yolo

# ---------------------------
# Install NVIDIA JetPack & L4T
# ---------------------------
sudo apt-get update
sudo apt-get install -y nvidia-jetpack nvidia-l4t-bootloader nvidia-l4t-kernel

# ---------------------------
# Update YOLO config file automatically
# ---------------------------
CONFIG_FILE="config_infer_primary_yoloV8.txt"
if [ -f "$CONFIG_FILE" ]; then
    sed -i 's|^onnx-file=.*|onnx-file=yolo11s.pt.onnx|' "$CONFIG_FILE"
else
    echo "Error: $CONFIG_FILE not found!"
fi

# Update deepstream_app_config.txt line 59
DEEPSTREAM_CFG="deepstream_app_config.txt"
if [ -f "$DEEPSTREAM_CFG" ]; then
    sed -i '59s|.*|config-file=config_infer_primary_yoloV8.txt|' "$DEEPSTREAM_CFG"
else
    echo "Error: $DEEPSTREAM_CFG not found!"
fi

echo "Setup complete! You can now run DeepStream with YOLO11."
