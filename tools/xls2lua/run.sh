export PYTHONPATH=./tools/py/lib/python2.7/site-packages:$PYTHONPATH
rm -Rf temp
rm -Rf ../../service/agent/res
mkdir temp
mkdir ../../service/agent/res
./py/bin/python2.7 xls2lua.py
../../build/bin/lua lua2game.lua
