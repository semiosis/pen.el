# I have not yet successfully compiled typesense

# cmake
(
cd "$(gc "http://github.com/Kitware/CMake")"
./bootstrap && make && make install
)

# snappy
(
cd "$(gc "http://github.com/google/snappy")"
git submodule update --init
cd build && cmake ../ && make
make install
)

# # bazel
# e ia bazel
# agi build-essential openjdk-11-jdk python zip unzip
# (
# cd /root/dump/programs/
# wget "https://github.com/bazelbuild/bazel/releases/download/6.3.2/bazel-6.3.2-dist.zip"
# unzip bazel-6.3.2-dist.zip -d bazel
# cd bazel
# env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
# cp -a output/bazel /usr/local/bin
# )

# # protobuf
# (
# agi g++ git bazel
# cd "$(gc "https://github.com/protocolbuffers/protobuf.git")"
# git submodule update --init --recursive
# bazel build :protoc :protobuf
# cp bazel-bin/protoc /usr/local/bin
# )

# typesense
agi libprotobuf-dev protobuf-compiler
agi libleveldb-dev libleveldb1d
(
cd "$(gc "https://github.com/gflags/gflags")"
mcd build
# Must be done manually
ccmake ..
# See: vi INSTALL.md
make
make install
)
(
cd "$(gc "http://github.com/google/glog")"
cmake -DBUILD_TESTING=0 -DWITH_GFLAGS=ON -DWITH_TLS=OFF -DWITH_UNWIND=OFF ..
cmake --build . && make install
)
# cmake -S . -B build -G "Unix Makefiles"
# cmake --build build

# Patch this if necessary
# /volumes/home/shane/var/smulliga/source/git/typesense/typesense/CMakeLists.txt
# diff --git a/CMakeLists.txt b/CMakeLists.txt
# index d0b038bc..4461d094 100644
# --- a/CMakeLists.txt
# +++ b/CMakeLists.txt
# @@ -73,6 +73,12 @@ include(cmake/s2.cmake)
#  include(cmake/lrucache.cmake)
#  include(cmake/kakasi.cmake)
#  
# +set(gflags_DIR /volumes/home/shane/var/smulliga/source/git/gflags/gflags/build)
# +find_package( gflags  REQUIRED PATHS ${CMAKE_SOURCE_DIR}/third_party/gflags NO_DEFAULT_PATH)
# +
# +set(glog_DIR /volumes/home/shane/var/smulliga/source/git/google/glog/build)
# +find_package( glog  REQUIRED PATHS ${CMAKE_SOURCE_DIR}/third_party/glog NO_DEFAULT_PATH)
# +
#  FIND_PACKAGE(OpenSSL 1.1.1 REQUIRED)
#  FIND_PACKAGE(Snappy REQUIRED)
#  FIND_PACKAGE(ZLIB REQUIRED)

(
agi libmpfr6 libmpfr-dev
agi libboost-all-dev
agi libqt5core5a
agi qtbase5-dev
cd "$(gc "http://github.com/fwilliams/unwind")"
mcd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j4
)

(
cd "$(gc "http://github.com/typesense/typesense")"
./build.sh --create-binary [--clean] [--depclean]
)
