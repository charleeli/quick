## Basic requirements
    [ubuntu 14.04 lts](http://www.ubuntu.com/download/desktop)
    [redis desktop manager](http://redisdesktop.com/)

## Ubuntu setup
```
sudo apt-get install cmake autoconf libreadline-dev git gitg
```

## Building from source
```
git clone https://github.com/charleeli/quick.git
cd quick
make
```

## Test
```
启动账号中心服务器
./build/bin/redis-server ./config/accountdc.conf

启动存储服务器
./build/bin/redis-server ./config/redis.conf

启动登陆服务器和游戏服务器
./build/bin/skynet config/config.login
./build/bin/skynet config/config.game
./build/bin/skynet config/config.game2

启动客户端
cd ./tools
../build/bin/lua client.lua
../build/bin/lua client2.lua

命令行输入
load_role
gm  {cmd="set level 99"}
```
