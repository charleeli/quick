export PYTHONPATH=./tools/py/lib/python2.7/site-packages:$PYTHONPATH
rm -Rf tmp
rm -Rf ../../service/res_mgr/res
mkdir tmp
mkdir ../../service/res_mgr/res
./py/python2.7 xls2tmp.py
../../build/bin/lua tmp2res.lua
