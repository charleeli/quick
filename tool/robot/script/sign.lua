--local ok, ret = client:run_cmd("login", {account="test", server_id="test"})
--if ok then
--    print("login ret:", ret.errcode)
--end

client:run_cmd("load_role")
client:run_cmd("view_sign")
client:run_cmd("gm", {cmd="set level 99"})
