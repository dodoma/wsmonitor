## wsmonitor

  http, websocket 通信解析器

  可用来观察 与目标机 指定端口 指定方向的 *文本* 通信内容


### 使用场景

  打开一个 websocket 应用后，你想知道他与后端服务器进行了哪些文本方式的数据交互（二进制的数据交互暂不解析）

  你可以通过浏览器的调试功能进行查看，或者，也可以通过此工具在终端下用文本方式查看。


### 安装

  要使用wsmonitor，你需要安装 lua，和几个简单的 lua 库

```
  $ luarocks install lua-zlib
  $ luarocks install lrexlib-pcre2
```

### 使用

  首先，你需要确定想要监听的 域名(或IP) 和 端口，然后执行

  $ ./dissector.sh direction host port | ./unws.lua

  其中:

  * direction 为通信方向，src 仅监控本机发出的请求，dst 仅监控本机接收的请求，all 为双向监控

  * host 为待监听服务器的域名或 ip

  * port 为待监听服务器的端口

  另外，在执行监控命令前，可以通过设置环境变量以改变程序的行为：

  1. WSMONITOR_SUPPRESS

```shell
  $ export WSMONITOR_SUPPRESS="ping|PING"
  $ ./dissector.sh all sdmj.pkgame.net 6001 | ./unws.lua
```
  以上命令将过滤内容中包含 ping 或者 PING 的请求，以抑制心跳包的输出。


  2. WSMONITOR_PRETTY

```shell
  $ export WSMONITOR_PRETTY=1
  $ ./dissector.sh all sdmj.pkgame.net 6001 | ./unws.lua
```
  以上命令将通信内容以JSON缩进方式输出，以方便查看。

![运行效果图](doc/pkgame.gif?raw=true "Metronome")


### TODO

1. 可能需要对拆分后的大包进行组包
