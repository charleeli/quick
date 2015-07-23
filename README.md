## Build
```
git clone https://github.com/charleeli/quick.git
cd quick
make
```

## Test
```
安装 mongo

启动账号中心服务器
./build/bin/redis-server ./config/redis/accountdc.conf

启动排行榜服务器
./build/bin/redis-server ./config/redis/ranking.conf

启动战斗同步服务器
cd ./battle
../build/bin/lua main.lua

启动登陆服和游戏服
./3rd/skynet/skynet config/config.login
./3rd/skynet/skynet config/config.game
./3rd/skynet/skynet config/config.game2

启动客户端
cd ./tools
../build/bin/lua client.lua
../build/bin/lua client2.lua
```

