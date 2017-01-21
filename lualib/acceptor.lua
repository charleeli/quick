local skynet = require 'skynet'

local M = {}

function M.connect_handler(delay) 
    if delay < 0 then 
        return { errcode = ERRCODE.E_FAKE_DISCONNECTED }
    end
    
    if delay > 0 then 
        skynet.sleep(delay * 100)
    end
    
    return { errcode = ERRCODE.E_OK }
end

return M
