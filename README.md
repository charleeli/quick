## Quick

a game server framework  inspired by [metoo](https://github.com/fztcjjl/metoo).

## Test
```
将tools/quick.sql导入到mysql

配置config/config.login中mysql连接信息

启动redis
./tools/redis.sh

./3rd/skynet/skynet config/config.login
./3rd/skynet/skynet config/config.game

cd ./tools
lua client.lua
```






