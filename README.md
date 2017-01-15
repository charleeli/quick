##Basic requirements
[ubuntu kylin 14.04/16.04 lts](http://www.ubuntukylin.com/downloads/)

[redis desktop manager](https://github.com/uglide/RedisDesktopManager/releases)

## Ubuntu setup
```
sudo apt-get install autoconf libreadline-dev git gitg
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
./build/bin/redis-server ./config/database/accountdb.conf

启动存储服务器
./build/bin/redis-server ./config/database/redis0.conf

启动登陆服务器和游戏服务器
./build/bin/skynet config/config.login
./build/bin/skynet config/config.game
./build/bin/skynet config/config.game2

启动客户端
cd ./tool
../build/bin/lua client.lua
../build/bin/lua client2.lua

命令行输入
load_role
gm  {cmd="set level 99"}
view_sign
send_world_chat {msg = "hello everyone!"}
send_private_chat {uuid = '5879ce6ee428a67f3fe05345', msg = 'hi 486'}
send_private_mail {to_uuid = '5879ce6ee428a67f3fe05345',subject='quick',content='quick is good'}
update_mailbox
```

## Benchmark
```
cd ./tool/benchmark
../../build/bin/lua benchmark.lua -s ./script/sign.lua


../../build/bin/lua client.lua
命令行输入
script ./script/sign.lua
```
