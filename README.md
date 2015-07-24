## Build
```
安装 [ubuntu 14.04.2 lts](http://www.ubuntu.com/download/desktop)
安装 [redis desktop manager](http://redisdesktop.com/)
安装 [mongo](http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/)
安装 [robomongo](http://robomongo.org/)

sudo apt-get install autoconf
sudo apt-get install libreadline-dev
sudo apt-get install git
sudo apt-get install gitg

git clone https://github.com/charleeli/quick.git
cd quick
make
```

## Test
```
启动账号中心服务器
./build/bin/redis-server ./config/redis/accountdc.conf

启动排行榜服务器
./build/bin/redis-server ./config/redis/ranking.conf

启动战斗同步服务器
./build/bin/lua ./battle/main.lua

启动登陆服务器和游戏服务器
./3rd/skynet/skynet config/config.login
./3rd/skynet/skynet config/config.game
./3rd/skynet/skynet config/config.game2

启动客户端
cd ./tools
../build/bin/lua client.lua
../build/bin/lua client2.lua
```
