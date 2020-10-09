SET SED=C:\msys64\usr\bin\sed.exe

PUSHD .
FOR %%I IN (C:\WinDDK\7600.16385.1) DO CALL %%I\bin\setenv.bat %%I fre %Platform% WIN7 no_oacr
POPD

IF %_BUILDARCH%==x86 SET Lib=%Lib%\Crt\i386;%DDK_LIB_DEST%\i386;%Lib%
IF %_BUILDARCH%==AMD64 SET Lib=%Lib%\Crt\amd64;%DDK_LIB_DEST%\amd64;%Lib%

SET Include=%Include%;%CRT_INC_PATH%

SET Path=%CD%;C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin;%Path%

FOR /F "DELIMS=" %%I IN ('WHERE cl.exe') DO %SED% "/_Complex/d" -i "%%~dpI..\..\..\inc\crt\math.h"

FOR %%I IN (
clang-cl.exe
lld-link.exe
llvm-lib.exe
) DO ^
FOR /F "TOKENS=2 DELIMS=-" %%J IN ('ECHO %%I') DO ^
FOR /F "DELIMS=" %%K IN ('WHERE %%I') DO ^
SET Path=%%~dpK;%Path%& MKLINK /H "%%~dpK%%J" "%%K"

IF %Platform%==x64 (SET M64=-m64) ELSE SET M64=-m32

FOR /F "DELIMS=" %%I IN ('WHERE cmake.exe') DO FOR /F "DELIMS=" %%J IN ('DIR /B /S "%%~dpI..\Windows-MSVC.cmake"') DO FOR %%K IN (
"/O2 /Ob2		/O1 -flto /GS- %M64%"
"\${_RTC1}		%M64%"
) DO FOR /F "TOKENS=1,* DELIMS=	" %%L IN (%%K) DO %SED% "s@%%L@%%M@" -i "%%J"

SETLOCAL ENABLEDELAYEDEXPANSION

FOR /F "DELIMS=" %%I IN ('DIR /O:-N /A:D-H /B') DO (
	SET Lib=!Lib!;%CD%\%%I
	SET Include=!Include!;%CD%\%%I

FOR /F %%J IN ('ECHO %%I ^| FIND /I "zlib-"') DO (
	CD %%J
	cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS=%M64%& nmake VERBOSE=1 zlibstatic
	CD ..
	SET ZLIB_INCLUDE_DIR=%CD%\%%J
	SET ZLIB_LIBRARY=!ZLIB_INCLUDE_DIR!\zlibstatic.lib
)
FOR /F %%J IN ('ECHO %%I ^| FIND /I "lpng"') DO (
	CD %%J
	cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS=%M64% -DZLIB_INCLUDE_DIR=!ZLIB_INCLUDE_DIR! -DZLIB_LIBRARY=!ZLIB_LIBRARY!& nmake VERBOSE=1 png_static
	CD ..
	SET PNG_PNG_INCLUDE_DIR=%CD%\%%J
	SET PNG_LIBRARY=!PNG_PNG_INCLUDE_DIR!\libpng16_static.lib
)

)

%SED% "/find_package(\(ZLIB\|PNG\)/d" -i CMakeLists.txt sharedlib\CMakeLists.txt

cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="%M64% -fno-builtin-pow" -DZLIB_LIBRARY=%ZLIB_LIBRARY% -DPNG_LIBRARY=%PNG_LIBRARY% -DPNG_PNG_INCLUDE_DIR=%PNG_PNG_INCLUDE_DIR% -DWITH_CRT_DLL=1 -DCMAKE_EXE_LINKER_FLAGS="/MANIFEST:NO libpng16_static.lib zlibstatic.lib"& FOR %%I IN (*.1) DO FOR /F "TOKENS=2 DELIMS=( " %%J IN ('FIND "add_executable" CMakeLists.txt ^| FIND "%%~nI"') DO nmake %%J VERBOSE=1
