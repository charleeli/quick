export PYTHONPATH=./tools/py/lib/python2.7/site-packages:$PYTHONPATH
rm -Rf temp
rm -Rf ../../service/res_mgr/res
mkdir temp
mkdir ../../service/res_mgr/res
./py/python2.7 xls2lua.py
../../build/bin/lua lua2game.lua
