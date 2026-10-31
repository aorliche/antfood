#! /bin/bash

if [[ -d build-flatpak ]]; then
	rm -rf build-flatpak
fi

if [[ -d CMakeFiles ]]; then
	rm -rf CMakeFiles
fi

if [[ -d scratch ]]; then
	rm -rf scratch
fi

if [[ -d build ]]; then
	rm -rf build
fi

cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_TESTING=OFF
