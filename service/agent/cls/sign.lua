local class = require 'pl.class'

local Sign = class()

function Sign:_init(sign_td)
    assert(sign_td, "new sign has no sign_td")
    self._sign_td = sign_td
end

function Sign:get_sign()
    return self._sign_td
end

function Sign:gen_proto()
    return {
        signed_today = self._sign_td.signed_today,
        signed_this_month = self._sign_td.signed_this_month,
    }
end

return Sign
