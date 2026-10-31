#! /bin/bash

flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak-builder build-flatpak --user --install-deps-from=flathub --force-clean --ccache \
	--install io.github.aorliche.antfood
