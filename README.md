## Basic requirements
    [ubuntu 16.04 lts](http://www.ubuntu.com/download/desktop)
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
启动账号服务器
./build/bin/redis-server ./config/db/accountdb.conf

启动存储服务器
./build/bin/redis-server ./config/db/gamedb.conf

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
view_sign
send_world_chat {msg = "hello everyone!"}
send_private_chat {uuid = '56d92ba7e428a68d57000486', msg = 'hi 486'}
send_private_mail {to_uuid = '56d92ba7e428a68d57000486',subject='quick',content='quick is good'}
```

## Benchmark
```
cd ./3rd/levent
cmake .
make

cd ./tools/robot
../../build/bin/lua client.lua
script ./script/sign.lua

../../build/bin/lua benchmark.lua -script ./script/sign.lua
```
