# netease-now-playing
Yet another way to get netease cloud music now playing on macOS

Inspired by Makito's project, [https://github.com/SumiMakito/NeteaseCloudMusic-Now-Playing](https://github.com/SumiMakito/NeteaseCloudMusic-Now-Playing)

使用动态链接库注入取得 macOS 网易云音乐的正在播放信息

### Details

[另一种方法获取 macOS 网易云音乐的正在播放](https://blog.0xbbc.com/2020/02/yet-another-way-to-get-netease-cloud-music-now-playing-on-macos/)

### Build
```bash
make
# 编译好的 libncmnp.dylib 会在 build 目录下
```

### Usage
```bash
# 将编译好的 libncmnp.dylib 复制到网易云音乐的 Frameworks 里
cp build/libncmnp.dylib /Applications/NeteaseMusic.app/Contents/Frameworks
# 用 insert_dylib (https://github.com/Tyilo/insert_dylib) 让网易云音乐依赖这个 dylib
insert_dylib @rpath/libncmnp.dylib NeteaseMusic
# 备份原始的二进制文件
mv NeteaseMusic NeteaseMusic_orig
# 将 patched 的二进制改名
mv NeteaseMusic_patched NeteaseMusic
```

然后就和往常一样直接使用即可～正在播放的信息会传给 script.py

### Python Script
默认的是需要将 `script.py` 放在 `/Applications/NeteaseMusic.app/Contents/MacOS` 下，如果要放在别的位置，或者执行别的 Python script，可以更改 `ncmnp.mm` 源代码中的 `PATHON_SCRIPT`

Python 解释器的位置在 `ncmnp.mm` 中的 `PYTHON_INTERPRETER` 里，需要按照实际情况更改

需要注意的是，这种方式注入的时候，默认的工作目录是 `/`，因此在 Python 脚本中输出文件的时候需要注意路径～
