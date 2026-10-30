# Maintainer: Anton Orlichenko <aorliche [at] gmail [dot] com>

pkgname=kfooddiary-git
_pkgname=${pkgname%-git}
pkgver=r0.16
pkgrel=1
pkgdesc='A text-first app for recording and viewing calories, weight, and other daily events'
arch=('x86_64')
url='https://github.com/aorliche/kfooddiary/'
license=('MIT')
provides=('kfooddiary')	

# Core runtime requirements
depends=('kirigami' 'qt6-declarative' 'qt6-svg' 'qqc2-desktop-style' 'ki18n' 'kcoreaddons')

# Requirements to compile the source
makedepends=('extra-cmake-modules' 'cmake' 'qt6-tools' 'git')

source=("${pkgname}::git+${url}")
sha256sums=('SKIP')

pkgver() {
	cd "${srcdir}/${pkgname}"
	printf "r0.%s" "$(git rev-list --count HEAD)"
}

build() {
	cmake -B build -S "${pkgname}" -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_TESTING=OFF
	cmake --build build
}

package() {
	DESTDIR="$pkgdir" cmake --install build
}
