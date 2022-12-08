ifdef CMAKE_TOOLCHAIN_FILE
	CMAKE_CONFIGURE_FLAGS=-D CMAKE_TOOLCHAIN_FILE="$(CMAKE_TOOLCHAIN_FILE)"
endif

CMAKE_BUILD_TYPE ?= Release
OPENCV_VER ?= 4.6.0
OPENCV_ROOT_DIR = $(shell pwd)/src/opencv
OPENCV_DIR = $(OPENCV_ROOT_DIR)/opencv-$(OPENCV_VER)
OPENCV_CONTRIB_VER ?= 4.6.0
OPENCV_CONTRIB_DIR = $(OPENCV_ROOT_DIR)/opencv_contrib-$(OPENCV_CONTRIB_VER)
OPENCV_CONFIGURATION_PRIVATE_HPP = $(OPENCV_DIR)/modules/core/include/opencv2/core/utils/configuration.private.hpp
PYTHON3_EXECUTABLE = $(shell which python3)
CMAKE_OPENCV_BUILD_DIR = $(shell pwd)/cmake_opencv_$(OPENCV_VER)
CMAKE_OPENCV_MODULE_SELECTION ?= -D BUILD_opencv_python2=OFF \
-D BUILD_opencv_python3=OFF \
-D BUILD_opencv_gapi=OFF
CMAKE_OPENCV_IMG_CODER_SELECTION ?= -D BUILD_PNG=ON \
-D BUILD_JPEG=ON \
-D BUILD_TIFF=ON \
-D BUILD_WEBP=ON \
-D BUILD_OPENJPEG=ON \
-D BUILD_JASPER=ON \
-D BUILD_OPENEXR=ON
CMAKE_OPENCV_OPTIONS ?= ""
DEFAULT_JOBS ?= 1
MAKE_BUILD_FLAGS ?= -j$(DEFAULT_JOBS)

CMAKE_OPENCV_MODULE_SELECTION ?= -D BUILD_opencv_calib3d=ON -D BUILD_opencv_core=ON -D BUILD_opencv_features2d=ON -D BUILD_opencv_flann=ON -D BUILD_opencv_highgui=ON -D BUILD_opencv_imgcodecs=ON -D BUILD_opencv_imgproc=ON -D BUILD_opencv_ml=ON -D BUILD_opencv_photo=ON -D BUILD_opencv_stitching=ON -D BUILD_opencv_ts=ON -D BUILD_opencv_video=ON -D BUILD_opencv_videoio=ON -D BUILD_opencv_dnn=ON -D BUILD_opencv_gapi=OFF -D BUILD_opencv_world=OFF -D BUILD_opencv_python2=OFF -D BUILD_opencv_python3=OFF -D BUILD_opencv_java=OFF
CMAKE_OPENCV_IMG_CODER_SELECTION ?= -D BUILD_PNG=ON -D BUILD_JPEG=ON -D BUILD_TIFF=ON -D BUILD_WEBP=ON -D BUILD_OPENJPEG=ON -D BUILD_JASPER=ON -D BUILD_OPENEXR=ON
CMAKE_OPTIONS ?= $(CMAKE_OPENCV_MODULE_SELECTION) $(CMAKE_OPENCV_IMG_CODER_SELECTION)
CMAKE_OPTIONS += $(CMAKE_CONFIGURE_FLAGS) $(CMAKE_OPENCV_OPTIONS)
ifdef TARGET_GCC_FLAGS
    CMAKE_OPTIONS += -DCMAKE_CXX_FLAGS="$(TARGET_GCC_FLAGS)" -DCMAKE_C_FLAGS="$(TARGET_GCC_FLAGS)"
endif

ENABLE_CV_CONTRIB ?= true
ifeq ($(ENABLE_CV_CONTRIB),true)
	CMAKE_OPTIONS += -DOPENCV_EXTRA_MODULES_PATH="$(OPENCV_CONTRIB_DIR)/modules" -D BUILD_opencv_hdf=OFF -D BUILD_opencv_freetype=OFF
endif

ENABLED_CV_MODULES ?= ""
# precompiled binaries
PRECOMPILED_DIR ?= $(shell pwd)/precompiled
HEADERS_TXT = $(CMAKE_OPENCV_BUILD_DIR)/modules/python_bindings_generator/headers.txt
HEADERS_TXT_OUT = $(PRECOMPILED_DIR)/headers.txt
CONFIGURATION_PRIVATE_HPP_OUT = $(PRECOMPILED_DIR)/configuration.private.hpp

.DEFAULT_GLOBAL := build

build: $(HEADERS_TXT_OUT)
	@echo > /dev/null

download_opencv_contrib:
	@ if [ "$(ENABLE_CV_CONTRIB)" = "true" ]; then \
		scripts/download_opencv_contrib.sh $(OPENCV_VER) src/cache src/opencv/ ; \
	fi

$(OPENCV_CONFIGURATION_PRIVATE_HPP): download_opencv_contrib
	@ scripts/download_opencv.sh $(OPENCV_VER) src/cache src/opencv/

$(CONFIGURATION_PRIVATE_HPP_OUT): $(OPENCV_CONFIGURATION_PRIVATE_HPP)
	@ mkdir -p "$(PRECOMPILED_DIR)"
	@ cp "$(OPENCV_CONFIGURATION_PRIVATE_HPP)" "$(CONFIGURATION_PRIVATE_HPP_OUT)"

$(HEADERS_TXT): $(CONFIGURATION_PRIVATE_HPP_OUT)
	@ mkdir -p "$(PRECOMPILED_DIR)" && \
	python3 "$(shell pwd)/patches/apply_patch.py" "$(OPENCV_DIR)" "$(OPENCV_VER)" ; \
	mkdir -p "$(CMAKE_OPENCV_BUILD_DIR)" && \
	cd "$(CMAKE_OPENCV_BUILD_DIR)" && \
	cmake -D CMAKE_BUILD_TYPE="$(CMAKE_BUILD_TYPE)" \
		-D CMAKE_INSTALL_PREFIX="$(PRECOMPILED_DIR)" \
		-D PYTHON3_EXECUTABLE="$(PYTHON3_EXECUTABLE)" \
		-D INSTALL_PYTHON_EXAMPLES=OFF \
		-D INSTALL_C_EXAMPLES=OFF \
		-D BUILD_EXAMPLES=OFF \
		-D BUILD_TESTS=OFF \
		-D BUILD_PERF_TESTS=OFF \
		-D BUILD_opencv_java=OFF \
		-D BUILD_opencv_gapi=OFF \
		-D BUILD_opencv_world=OFF \
		-D OPENCV_ENABLE_NONFREE=OFF \
		-D OPENCV_GENERATE_PKGCONFIG=ON \
		-D OPENCV_PC_FILE_NAME=opencv4.pc \
		-D BUILD_ZLIB=ON \
		-D BUILD_opencv_gapi=OFF \
		-D CMAKE_C_FLAGS=-DPNG_ARM_NEON_OPT=0 \
		-D CMAKE_CXX_FLAGS=-DPNG_ARM_NEON_OPT=0 \
		-D CMAKE_TOOLCHAIN_FILE="$(TOOLCHAIN_FILE)" \
		$(CMAKE_OPTIONS) "$(OPENCV_DIR)" && \
	make "$(MAKE_BUILD_FLAGS)" && \
	make install

$(HEADERS_TXT_OUT): $(HEADERS_TXT)
	@ if [ -x "$(which gsed)" ]; then \
		cp "$(HEADERS_TXT)" "$(HEADERS_TXT_OUT)" ; \
		gsed -i 's#$(OPENCV_DIR)/modules/#precompiled/include/opencv4/opencv2/#g' "$(HEADERS_TXT_OUT)" ; \
	else \
		sed 's#$(OPENCV_DIR)/modules/#precompiled/include/opencv4/opencv2/#g' "$(HEADERS_TXT)" > "$(HEADERS_TXT_OUT)" ; \
	fi
