$env.Path += ";C:\Program Files\CMake\Bin"
$env.Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\"
curl -o c:\zlib.zip https://zlib.net/zlib1211.zip
unzip -d c:\ c:\zlib.zip
cd c:\zlib-1.2.11
"C:\Program Files\CMake\Bin\cmake" -DCMAKE_INSTALL_PREFIX=C:\lib\zlib -G "Visual Studio 15 Win64"
"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\msbuild" INSTALL.vcxproj
cd c:\
rm -r c:\zlib-1.2.11
rm -r c:\zlib.zip
