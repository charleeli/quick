local Sign = class()

function Sign:ctor(sign_orm)
    assert(sign_orm, "new sign has no sign_orm")
    self.sign = sign_orm
end

function Sign:dtor()
end

function Sign:get_sign()
    return self.sign
end

function Sign:gen_proto()
    return {
        full_duty_awarded = self.sign.full_duty_awarded,
        resigned_this_month = self.sign.resigned_this_month,
        signed_today = self.sign.signed_today,
        signed_this_month = self.sign.signed_this_month,
    }
end

return Sign
