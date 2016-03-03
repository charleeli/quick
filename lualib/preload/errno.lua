ERRNO = {
	E_OK					    = 0,		-- 正确
	E_ERROR                     = -1,       -- 错误
	E_ARGS                      = -2,       -- 参数错误
	E_ROLE_EXISTS				= -3,		-- 玩家角色已存在
	E_DB_ERROR					= -4,		-- 数据库操作失败
	E_SERVICE_UNAVAILABLE       = -5,       -- 服务不可用
	E_FREQUENCY                 = -6,       -- 频率太高
	E_CHAT_EMPTY                = -7,       -- 聊天消息长度为0
	E_CHAT_OVENLEN              = -8,       -- 聊天消息过长
	E_CONTENT_SENSITIVE         = -9,       -- 内容敏感
	E_SUBJECT_LONG              = -10,      -- 标题太长
	E_CONTENT_LONG              = -11,      -- 内容太长
	E_LOGIN_CONFLICT            = -12,      -- 登陆冲突
	E_ROLE_NOT_EXISTS           = -13,		-- 玩家角色不存在
	E_ROLE_NOT_ONLINE           = -14,		-- 玩家角色不在线
}
