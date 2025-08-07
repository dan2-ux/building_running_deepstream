echo "Starting to download"

pip3 install meson
pip3 install ninja

git clone https://github.com/GNOME/glib.git
cd glib
git checkout 2.76.6
sudo apt update
sudo apt install meson
meson build --prefix=/usr
ninja -C build/
cd build/
ninja install

pkg-config --modversion glib-2.0

sudo apt install \
libssl3 \
libssl-dev \
libgstreamer1.0-0 \
gstreamer1.0-tools \
gstreamer1.0-plugins-good \
gstreamer1.0-plugins-bad \
gstreamer1.0-plugins-ugly \
gstreamer1.0-libav \
libgstreamer-plugins-base1.0-dev \
libgstrtspserver-1.0-0 \
libjansson4 \
libyaml-cpp-dev

cd /opt/nvidia/deepstream/deepstream-7.1
./update_rtpmanager.sh

sudo git clone https://github.com/confluentinc/librdkafka.git

cd librdkafka
sudo git checkout tags/v2.2.0
sudo ./configure --enable-ssl
sudo make
sudo make install

sudo mkdir -p /opt/nvidia/deepstream/deepstream/lib
sudo cp /usr/local/lib/librdkafka* /opt/nvidia/deepstream/deepstream-7.1/lib
sudo ldconfig


pip install --upgrade pip setuptools wheel
cd ~
pip install -U pip
git clone https://github.com/ultralytics/ultralytics
cd ultralytics
pip install -e ".[export]" onnxslim --use-deprecated=legacy-resolver
pip install onnx --extra-index-url https://pypi.ngc.nvidia.com

pip3 install torch
pip install numpy
pip uninstall opencv-python
pip install opencv-python==4.6.0.66
pip uninstall numpy
pip install numpy==1.23.5
pip install tqdm
pip install torchvision==0.15.2


cd ~
git clone https://github.com/marcoslucianops/DeepStream-Yolo


cp ~/DeepStream-Yolo/utils/export_yolo11.py ~/ultralytics
cd ultralytics

wget https://github.com/ultralytics/assets/releases/download/v8.3.0/yolo11s.pt

python3 export_yolo11.py -w yolo11s.pt

cp yolo11s.pt.onnx labels.txt ~/DeepStream-Yolo
cd ~/DeepStream-Yolo


export CUDA_VER=12.6

make -C nvdsinfer_custom_impl_Yolo clean && make -C nvdsinfer_custom_impl_Yolo


sudo apt-get update
sudo apt-get install nvidia-jetpack

sudo apt-get install nvidia-l4t-bootloader nvidia-l4t-kernel

echo "Now you can run deepstream"
