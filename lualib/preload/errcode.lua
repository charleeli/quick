ERRCODE = {
    E_OK                = 0,        -- 正确
    E_ERROR             = -1,       -- 错误
    E_ARGS              = -2,       -- 参数错误
    E_DB                = -3,       -- 数据库操作失败
    E_SERVICE           = -4,       -- 服务不可用
    E_FREQUENCY         = -5,       -- 频率太高
    E_LOGIN             = -6,       -- 登陆冲突
    E_ONLINE            = -7,       -- 角色不在线
    E_CHAT_EMPTY        = -8,       -- 聊天消息长度为0
    E_CHAT_OVENLEN      = -9,       -- 聊天消息过长
    E_CONTENT_SENSITIVE = -10,      -- 内容敏感
    E_SUBJECT_LONG      = -11,      -- 标题太长
    E_CONTENT_LONG      = -12,      -- 内容太长
    E_FAKE_DISCONNECTED = -13,      -- 假装失败
}
