#!/bin/bash
CMAKE=1

# Check arguments
while test $# -gt 0
do
	case "$1" in
		--qt) echo "Qt enabled"
			QT=1
			CMAKE_ARGS="-DUSING_QT_UI=ON ${CMAKE_ARGS}"
			;;
		--qtbrew) echo "Qt enabled (homebrew)"
			QT=1
			CMAKE_ARGS="-DUSING_QT_UI=ON -DCMAKE_PREFIX_PATH=$(brew --prefix qt5) ${CMAKE_ARGS}"
			;;
		--ios) CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=cmake/Toolchains/ios.cmake -GXcode ${CMAKE_ARGS}"
			TARGET_OS=iOS
			;;
		--rpi-armv6)
			CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=cmake/Toolchains/raspberry.armv6.cmake ${CMAKE_ARGS}"
			;;
		--rpi)
			CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=cmake/Toolchains/raspberry.armv7.cmake ${CMAKE_ARGS}"
			;;
                --rpi64)
                        CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=cmake/Toolchains/raspberry.armv8.cmake ${CMAKE_ARGS}"
                        ;;
		--android) CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=android/android.toolchain.cmake ${CMAKE_ARGS}"
			TARGET_OS=Android
			PACKAGE=1
			;;
		--simulator) echo "Simulator mode enabled"
			CMAKE_ARGS="-DSIMULATOR=ON ${CMAKE_ARGS}"
			;;
		--release)
			CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Release ${CMAKE_ARGS}"
			;;
		--debug)
			CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Debug ${CMAKE_ARGS}"
			;;
		--headless) echo "Headless mode enabled"
			CMAKE_ARGS="-DHEADLESS=ON ${CMAKE_ARGS}"
			;;
		--libretro) echo "Build Libretro core"
			CMAKE_ARGS="-DLIBRETRO=ON ${CMAKE_ARGS}"
			;;
		--libretro_android) echo "Build Libretro Android core"
		        CMAKE_ARGS="-DLIBRETRO=ON -DCMAKE_TOOLCHAIN_FILE=${NDK}/build/cmake/android.toolchain.cmake -DANDROID_ABI=${APP_ABI} ${CMAKE_ARGS}"
			;;
		--unittest) echo "Build unittest"
			CMAKE_ARGS="-DUNITTEST=ON ${CMAKE_ARGS}"
			;;
		--no-package) echo "Packaging disabled"
			PACKAGE=0
			;;
		--clang) echo "Clang enabled"
			export CC=/usr/bin/clang
			export CXX=/usr/bin/clang++
			;;
		--sanitize) echo "Enabling address-sanitizer if available"
			CMAKE_ARGS="-DUSE_ADDRESS_SANITIZER=ON ${CMAKE_ARGS}"
			;;
		*) MAKE_OPT="$1 ${MAKE_OPT}"
			;;
	esac
	shift
done

if [ ! -z "$TARGET_OS" ]; then
	echo "Building for $TARGET_OS"
	BUILD_DIR="$(tr [A-Z] [a-z] <<< build-"$TARGET_OS")"
else
	echo "Building for native host."
	BUILD_DIR="build"
fi

# Strict errors. Any non-zero return exits this script
set -e

mkdir -p ${BUILD_DIR}
pushd ${BUILD_DIR}

cmake $CMAKE_ARGS ..

if [ "$TARGET_OS" != "iOS" ]; then
	make -j4 $MAKE_OPT
else
	xcodebuild clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO PRODUCT_BUNDLE_IDENTIFIER="org.ppsspp.ppsspp" -sdk iphoneos -configuration Release
	ln -sf Release-iphoneos Payload
	echo '<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
			<key>platform-application</key>
			<true/>
			<key>com.apple.private.security.no-container</key>
			<true/>
			<key>get-task-allow</key>
			<true/>
		</dict>
		</plist>' > ent.xml
	ldid -Sent.xml Payload/PPSSPP.app/PPSSPP
	version_number=`echo "$(git describe --tags --match="v*" | sed -e 's@-\([^-]*\)-\([^-]*\)$@-\1-\2@;s@^v@@;s@%@~@g')"`
	echo ${version_number} > Payload/PPSSPP.app/Version.txt
	zip -r9 PPSSPP_v${version_number}.ipa Payload/PPSSPP.app
fi
popd
