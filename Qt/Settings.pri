VERSION = 0.9.8
DEFINES += USING_QT_UI USE_FFMPEG
unix:!qnx:!symbian:!mac: CONFIG += linux
maemo5|contains(MEEGO_EDITION,harmattan): CONFIG += maemo

# Global specific
win32:CONFIG(release, debug|release): CONFIG_DIR = $$join(OUT_PWD,,,/release)
else:win32:CONFIG(debug, debug|release): CONFIG_DIR = $$join(OUT_PWD,,,/debug)
else:CONFIG_DIR=$$OUT_PWD
OBJECTS_DIR = $$CONFIG_DIR/.obj/$$TARGET
MOC_DIR = $$CONFIG_DIR/.moc/$$TARGET
UI_DIR = $$CONFIG_DIR/.ui/$$TARGET
P = $$_PRO_FILE_PWD_/..
INCLUDEPATH += $$P/ext/zlib $$P/Common

symbian {
	exists($$P/.git): GIT_VERSION = $$system(git describe --always)
	isEmpty(GIT_VERSION): GIT_VERSION = $$VERSION
} else {
	# QMake seems to change how it handles quotes with every version. This works for most systems:
	exists($$P/.git): GIT_VERSION = '\\"$$system(git describe --always)\\"'
	isEmpty(GIT_VERSION): GIT_VERSION = '\\"$$VERSION\\"'
}
DEFINES += PPSSPP_GIT_VERSION=\"$$GIT_VERSION\"

win32-msvc* {
	DEFINES += _MBCS GLEW_STATIC _CRT_SECURE_NO_WARNINGS "_VARIADIC_MAX=10"
	contains(DEFINES, UNICODE): DEFINES += _UNICODE
	QMAKE_ALLFLAGS_RELEASE += /O2 /fp:fast
} else {
	DEFINES += __STDC_CONSTANT_MACROS
	QMAKE_CXXFLAGS += -Wno-unused-function -Wno-unused-variable -Wno-unused-parameter -Wno-multichar -Wno-uninitialized -Wno-ignored-qualifiers -Wno-missing-field-initializers
	greaterThan(QT_MAJOR_VERSION,4): CONFIG+=c++11
	else: QMAKE_CXXFLAGS += -std=c++11
	QMAKE_CFLAGS_RELEASE ~= s/-O.*/
	QMAKE_CXXFLAGS_RELEASE ~= s/-O.*/
	QMAKE_ALLFLAGS_RELEASE += -O3 -ffast-math
}
# Arch specific

contains(QT_ARCH, ".*86.*")|contains(QMAKE_TARGET.arch, ".*86.*") {
	!win32-msvc*: QMAKE_ALLFLAGS += -msse2
	else: QMAKE_ALLFLAGS += /arch:SSE2
} else { # Assume ARM
	DEFINES += ARM
	CONFIG += arm
}
arm:!symbian {
	CONFIG += armv7
	QMAKE_CFLAGS_RELEASE ~= s/-mfpu.*/
	QMAKE_CFLAGS_DEBUG ~= s/-mfpu.*/
	QMAKE_ALLFLAGS_DEBUG += -march=armv7-a -mtune=cortex-a8 -mfpu=neon -ftree-vectorize
	QMAKE_ALLFLAGS_RELEASE += -march=armv7-a -mtune=cortex-a8 -mfpu=neon -ftree-vectorize
}

contains(QT_CONFIG, opengles.) {
	DEFINES += USING_GLES2
	# How else do we know if the environment prefers windows?
	!linux|android|maemo {
		DEFINES += MOBILE_DEVICE
		CONFIG += mobile_platform
	}
}

# Platform specific
contains(MEEGO_EDITION,harmattan): DEFINES += "_SYS_UCONTEXT_H=1"
maemo: DEFINES += MAEMO

win32 {
	PRECOMPILED_HEADER = $$P/Windows/stdafx.h
	PRECOMPILED_SOURCE = $$P/Windows/stdafx.cpp
	INCLUDEPATH += $$P $$P/ffmpeg/Windows/$${QMAKE_TARGET.arch}/include
}
macx {
	QMAKE_MAC_SDK=macosx10.9
	INCLUDEPATH += $$P/ffmpeg/macosx/x86_64/include
}
ios {
	DEFINES += IOS
	INCLUDEPATH += $$P/ffmpeg/ios/universal/include
}
android {
	DEFINES += ANDROID
	INCLUDEPATH += $$P/ffmpeg/android/armv7/include $$P/native/ext/libzip
}

linux:!android {
	arm: INCLUDEPATH += $$P/ffmpeg/linux/armv7/include
	else {
		contains(QT_ARCH, x86_64) QMAKE_TARGET.arch = x86_64
		else: QMAKE_TARGET.arch = x86
		INCLUDEPATH += $$P/ffmpeg/linux/$${QMAKE_TARGET.arch}/include
	}
}
# Fix 32-bit/64-bit defines
!arm {
	contains(QMAKE_TARGET.arch, x86_64): DEFINES += _M_X64
	else: DEFINES += _M_IX86
}

qnx {
	# Use mkspec: unsupported/qws/qnx-armv7-g++
	DEFINES += BLACKBERRY "_QNX_SOURCE=1" "_C99=1"
	INCLUDEPATH += $$P/ffmpeg/blackberry/armv7/include
}
symbian {
	DEFINES += "BOOST_COMPILER_CONFIG=\"$$EPOCROOT/epoc32/include/stdapis/boost/mpl/aux_/config/gcc.hpp\"" SYMBIAN_OGLES_DLL_EXPORTS
	QMAKE_CXXFLAGS += -marm -Wno-parentheses -Wno-comment -Wno-unused-local-typedefs
	INCLUDEPATH += $$EPOCROOT/epoc32/include/stdapis
	INCLUDEPATH += $$P/ffmpeg/symbian/armv6/include
}
maemo {
	DEFINES += __GL_EXPORTS
}

# Handle flags for both C and C++
QMAKE_CFLAGS += $$QMAKE_ALLFLAGS
QMAKE_CXXFLAGS += $$QMAKE_ALLFLAGS
QMAKE_CFLAGS_DEBUG += $$QMAKE_ALLFLAGS_DEBUG
QMAKE_CXXFLAGS_DEBUG += $$QMAKE_ALLFLAGS_DEBUG
QMAKE_CFLAGS_RELEASE += $$QMAKE_ALLFLAGS_RELEASE
QMAKE_CXXFLAGS_RELEASE += $$QMAKE_ALLFLAGS_RELEASE
