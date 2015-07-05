local Skynet = require 'skynet'

local M = {}

function M.connect_handler(delay) 
    if delay < 0 then 
        return
    end
    
    if delay > 0 then 
        Skynet.sleep(delay * 100)
    end
    
    return Skynet.retpack({ errcode = ERRNO.E_OK })
end

return M
