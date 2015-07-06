## Test
```
安装 mongo mysql

将tools/quick.sql导入到mysql

配置config/config.login中mysql连接信息

启动redis
./tools/redis.sh

./3rd/skynet/skynet config/config.login
./3rd/skynet/skynet config/config.game
./3rd/skynet/skynet config/config.game2

cd ./tools
lua client.lua
lua client2.lua
```

