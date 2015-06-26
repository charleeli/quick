local RoleApi = require 'apis.role_api'

function load_role(args)
    return RoleApi.apis.load_role()
end
