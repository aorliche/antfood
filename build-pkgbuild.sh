#! /bin/bash

if [[ -d scratch ]]; then
	rm -rf scratch
fi

mkdir scratch
cp PKGBUILD scratch
cd scratch
makepkg
