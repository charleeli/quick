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

启动redis
./tools/redis.sh

cd ./battle
../build/bin/lua main.lua

./3rd/skynet/skynet config/config.login
./3rd/skynet/skynet config/config.game
./3rd/skynet/skynet config/config.game2

cd ./tools
../build/bin/lua client.lua
../build/bin/lua client2.lua
```

