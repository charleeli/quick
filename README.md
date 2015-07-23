## Build
```
git clone https://github.com/charleeli/quick.git
cd quick
make
```

## Test
```
安装 mongo mysql

将tools/quick.sql导入到mysql

配置config/config.login中mysql连接信息

启动redis缓存池
./tools/redis.sh

启动排行榜服务器
./build/bin/redis-server ./config/ranking.conf

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

