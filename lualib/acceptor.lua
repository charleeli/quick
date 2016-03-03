local skynet = require 'skynet'

local M = {}

function M.connect_handler(delay) 
    if delay < 0 then 
        return
    end
    
    if delay > 0 then 
        skynet.sleep(delay * 100)
    end
    
    return skynet.retpack({ errcode = ERRNO.E_OK })
end

return M
