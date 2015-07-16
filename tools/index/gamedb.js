//使用方法: mongo host:port/db_name js_name

//给role集合建立索引
db.role.ensureIndex( { "account": 1 });
db.role.ensureIndex( { "uid": 1 }, { unique: true } );
db.role.ensureIndex( { "uuid": 1 }, { unique: true } );

//给mailbox集合建立索引
db.mailbox.ensureIndex( { "role_uuid": 1 }, { unique: true } );
