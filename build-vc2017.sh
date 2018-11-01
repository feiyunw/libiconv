#!/bin/sh
if [ ! -f configure ]; then
    echo Install Cygwin packages: autoconf make automake gcc-core gettext-devel git gperf groff m4 patch
    echo Then run ./autogen.sh before this script.
    exit 1
fi

# Set PlatformTarget
# Remember to "make clean" after switching PlatformTarget, before running this script again.
#PlatformTarget=x64
if [ -z "${PlatformTarget}" ]; then
    PlatformTarget=x86
fi

# Get WindowsSdkDir
#WindowsSdkDir='C:\\Program Files (x86)\\Windows Kits\\10\\'
if [ -z "${WindowsSdkDir}" ]; then
    REGISTRY1=/HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/Microsoft/Microsoft\ SDKs/Windows/v10.0
    REGISTRY2=/HKEY_CURRENT_USER/SOFTWARE/Wow6432Node/Microsoft/Microsoft\ SDKs/Windows/v10.0
    REGISTRY3=/HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Microsoft\ SDKs/Windows/v10.0
    REGISTRY4=/HKEY_CURRENT_USER/SOFTWARE/Microsoft/Microsoft\ SDKs/Windows/v10.0
    if [ ! `regtool -q check "${REGISTRY1}/InstallationFolder"` ]; then
        WindowsSdkDir=`regtool get "${REGISTRY1}/InstallationFolder"`
    elif [ ! `regtool -q check "$REGISTRY2/InstallationFolder"` ]; then
        WindowsSdkDir=`regtool get "${REGISTRY2}/InstallationFolder"`
    elif [ ! `regtool -q check "$REGISTRY3/InstallationFolder"` ]; then
        WindowsSdkDir=`regtool get "${REGISTRY3}/InstallationFolder"`
    elif [ ! `regtool -q check "$REGISTRY4/InstallationFolder"` ]; then
        WindowsSdkDir=`regtool get "${REGISTRY4}/InstallationFolder"`
    else
        echo Cannot find WindowsSdkDir
        exit 1;
    fi
fi

if [ ! -d "${WindowsSdkDir}" ]; then
    echo Cannot find WindowsSdkDir ${WindowsSdkDir}
    exit 1
fi

# Set WindowsSDKVersion
#WindowsSDKVersion='10.0.16299.0'
#WindowsSDKVersion='10.0.15063.0'
#WindowsSDKVersion='10.0.14393.0'
#WindowsSDKVersion='10.0.10586.0'
#WindowsSDKVersion='10.0.10240.0'
if [ -z "${WindowsSDKVersion}" ]; then
    WindowsSDKVersion='10.0.17134.0'
fi

# Set VSINSTALLDIR
VSINSTALLDIR='D:\Program Files (x86)\Microsoft Visual Studio\2017\Community\'
#VSINSTALLDIR='E:\Program Files (x86)\Microsoft Visual Studio\2017\Community\'
#VSINSTALLDIR='F:\Program Files (x86)\Microsoft Visual Studio\2017\Community\'
#VSINSTALLDIR='G:\Program Files (x86)\Microsoft Visual Studio\2017\Community\'
if [ -z "${VSINSTALLDIR}" ]; then
    VSINSTALLDIR='C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\'
fi

# Set VSToolsVersion
if [ -z "${VSToolsVersion}" ]; then
    VSToolsVersion='14.15.26726'
fi

echo PlatformTarget=${PlatformTarget}
echo WindowsSdkDir=${WindowsSdkDir}
echo WindowsSDKVersion=${WindowsSDKVersion}
echo VSINSTALLDIR=${VSINSTALLDIR}
echo VSToolsVersion=${VSToolsVersion}
echo

# Verify WindowsSdkIncludeDir and WindowsSdkLibDir
WindowsSdkIncludeDir="${WindowsSdkDir}"'Include\'"${WindowsSDKVersion}"
WindowsSdkLibDir="${WindowsSdkDir}"'Lib\'"${WindowsSDKVersion}"
if [ ! -d "${WindowsSdkIncludeDir}" ]; then
        echo Cannot find WindowsSdkIncludeDir ${WindowsSdkIncludeDir}
    echo Modify WindowsSDKVersion value and run again.
    exit 1
fi
if [ ! -d "${WindowsSdkLibDir}" ]; then
        echo Cannot find WindowsSdkLibDir ${WindowsSdkLibDir}
    echo Modify WindowsSDKVersion value and run again.
    exit 1
fi

# Windows C library headers and libraries.
WindowsCrtIncludeDir="${WindowsSdkIncludeDir}\\ucrt"
WindowsCrtLibDir="${WindowsSdkLibDir}"'\ucrt\'"${PlatformTarget}"
if [ ! -f "${WindowsCrtIncludeDir}\\stdio.h" ]; then 
    echo Cannot locate ${WindowsCrtIncludeDir}\\stdio.h
    exit 1
fi
if [ ! -f "${WindowsCrtLibDir}\\ucrt.lib" ]; then
    echo Cannot locate ${WindowsCrtLibDir}\\ucrt.lib
    exit 1
fi
INCLUDE="${WindowsCrtIncludeDir};$INCLUDE"
LIB="${WindowsCrtLibDir};$LIB"

# Windows API headers and libraries.
INCLUDE="${WindowsSdkIncludeDir}\\um;${WindowsSdkIncludeDir}\\shared;$INCLUDE"
LIB="${WindowsSdkLibDir}"'\um\'"${PlatformTarget};$LIB"

# Visual C++ tools, headers and libraries.
VCToolsInstallDir="${VSINSTALLDIR}"'VC\Tools\MSVC\'"${VSToolsVersion}"
if [ ! -f "${VCToolsInstallDir}\\include\\stdarg.h" ]; then
        echo Cannot locate ${VCToolsInstallDir}\\include\\stdarg.h
    echo Modify VSINSTALLDIR and VSToolsVersion values and run again.
    exit 1
fi
INCLUDE="${VCToolsInstallDir}\\include;$INCLUDE"
LIB="${VCToolsInstallDir}"'\lib\'"${PlatformTarget};$LIB"

export INCLUDE LIB
#echo INCLUDE=${INCLUDE}
#echo LIB=${LIB}
#echo
#read -n1 -p "Verify the above settings. Press CTRL-C to abort, or other keys to continue..."

[ -d $HOME/msvc/ ] || mkdir $HOME/msvc/
cp gnulib/build-aux/ar-lib $HOME/msvc/ && chmod a+x $HOME/msvc/ar-lib
cp gnulib/build-aux/compile $HOME/msvc/ && chmod a+x $HOME/msvc/compile

if [ "${PlatformTarget}" == "x86" ]; then
    export PATH=`cygpath -u "${VCToolsInstallDir}"`/bin/Hostx86/x86:`cygpath -u "${WindowsSdkDir}"`bin/"${WindowsSDKVersion}"/x86:"$PATH"
    win32_target=_WIN32_WINNT_WIN7
    ./configure --host=i686-w64-mingw32 --prefix=/usr/local/msvc32 \
        CC="$HOME/msvc/compile cl -nologo" \
        CFLAGS="-MD /utf-8" \
        CXX="$HOME/msvc/compile cl -nologo" \
        CXXFLAGS="-MD /utf-8" \
        CPPFLAGS="-D_WIN32_WINNT=$win32_target" \
        RC="windres -Fpe-i386" \
        WINDRES="windres -Fpe-i386" \
        LDFLAGS="/MACHINE:X86" \
        LD="link" \
        NM="dumpbin -symbols" \
        STRIP=":" \
        AR="$HOME/msvc/ar-lib lib" \
        RANLIB=":"
        make
        make check
        make install
elif [ "${PlatformTarget}"=="x64" ]; then
    export PATH=`cygpath -u "${VCToolsInstallDir}"`/bin/Hostx64/x64:`cygpath -u "${WindowsSdkDir}"`bin/"${WindowsSDKVersion}"/x64:"$PATH"
    win32_target=_WIN32_WINNT_WIN7
    ./configure --host=x86_64-w64-mingw32 --prefix=/usr/local/msvc64 \
        CC="$HOME/msvc/compile cl -nologo" \
        CFLAGS="-MD /utf-8" \
        CXX="$HOME/msvc/compile cl -nologo" \
        CXXFLAGS="-MD /utf-8" \
        CPPFLAGS="-D_WIN32_WINNT=$win32_target" \
        RC="windres -Fpe-x86-64" \
        WINDRES="windres -Fpe-x86-64" \
        LDFLAGS="/MACHINE:X64" \
        LD="link" \
        NM="dumpbin -symbols" \
        STRIP=":" \
        AR="$HOME/msvc/ar-lib lib" \
        RANLIB=":"
        make
        make check
        make install
else
    echo Modify PlatformTarget value and run again.
    exit 1
fi

