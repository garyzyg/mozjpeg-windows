PUSHD .
FOR %%I IN (C:\WinDDK\7600.16385.1) DO CALL %%I\bin\setenv.bat %%I fre %Platform% WIN7 no_oacr
POPD

IF %_BUILDARCH%==x86 SET Lib=%Lib%\Crt\i386;%DDK_LIB_DEST%\i386;%Lib%
IF %_BUILDARCH%==AMD64 SET Lib=%Lib%\Crt\amd64;%DDK_LIB_DEST%\amd64;%Lib%

SET Include=%Include%;%CRT_INC_PATH%

SET Path=%CD%;C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin;%Path%

FOR /F "DELIMS=" %%I IN ('WHERE cmake.exe') DO FOR /F "DELIMS=" %%J IN ('DIR /B /S "%%~dpI..\Windows-MSVC.cmake"') DO FOR %%K IN (
"/O2 /Ob2		/O1 /GL /GS- /DPNG_SUPPORTED"
"\${_RTC1}		 "
) DO FOR /F "TOKENS=1,* DELIMS=	" %%L IN (%%K) DO C:\msys64\usr\bin\sed.exe "s@%%L@%%M@" -i "%%J"

SETLOCAL ENABLEDELAYEDEXPANSION

FOR /F "DELIMS=" %%I IN ('DIR /O:-N /A:D-H /B') DO (
	SET Lib=!Lib!;%CD%\%%I
	SET Include=!Include!;%CD%\%%I

FOR /F %%J IN ('ECHO %%I ^| FIND /I "zlib-"') DO (
	CD %%J
	cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXE_LINKER_FLAGS=/MANIFEST:NO& nmake VERBOSE=1 zlibstatic
	CD ..
)
FOR /F %%J IN ('ECHO %%I ^| FIND /I "lpng"') DO FOR /F %%K IN ('DIR /B /A:D zlib-*') DO (
	CD %%J
	cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXE_LINKER_FLAGS=/MANIFEST:NO -DZLIB_LIBRARY=${ZLIB_INCLUDE_DIR}\zlibstatic.lib -DZLIB_INCLUDE_DIR=%CD%\..\%%K& nmake VERBOSE=1 png_static
	CD ..
)

)

C:\msys64\usr\bin\sed.exe "s@\${CJPEG_BMP_SOURCES}@& rdpng.c@" -i CMakeLists.txt
cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DWITH_CRT_DLL=1 -DCMAKE_EXE_LINKER_FLAGS="/MANIFEST:NO libpng16_static.lib zlibstatic.lib"& FOR %%I IN (*.1) DO FOR /F "TOKENS=2 DELIMS=( " %%J IN ('FIND "add_executable" CMakeLists.txt ^| FIND "%%~nI"') DO nmake %%J VERBOSE=1
