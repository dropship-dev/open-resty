# OpenResty Lua Modules Guide

Hướng dẫn thêm và sử dụng các module Lua trong OpenResty Helm chart.

## Các Module Lua có sẵn trong OpenResty

OpenResty image đã có sẵn nhiều modules:

### Core Modules

- `ngx.ssl` - SSL/TLS operations
- `ngx.socket` - Socket operations
- `ngx.timer` - Timer operations
- `ngx.semaphore` - Semaphore operations

### HTTP Modules

- `resty.http` - HTTP client
- `resty.websocket` - WebSocket client
- `resty.limit.traffic` - Rate limiting

### Database Modules

- `resty.redis` - Redis client
- `resty.mysql` - MySQL client
- `resty.postgres` - PostgreSQL client

### Security Modules

- `resty.jwt` - JWT handling
- `resty.aes` - AES encryption
- `resty.hmac` - HMAC operations

### Utility Modules

- `cjson` - JSON operations
- `resty.string` - String utilities
- `resty.sha1` - SHA1 hashing

## Cách thêm Module mới

### 1. Sử dụng Luarocks (Recommended)

Thêm vào `values.yaml`:

```yaml
openresty:
  modules:
    enabled: true
    luarocks:
      - "lua-resty-auto-ssl" # Auto SSL with Let's Encrypt
      - "lua-resty-redis" # Redis client
      - "lua-resty-mysql" # MySQL client
      - "lua-resty-jwt" # JWT handling
      - "lua-resty-http" # HTTP client
      - "lua-resty-websocket" # WebSocket support
      - "lua-resty-limit-traffic" # Rate limiting
```

### 2. Sử dụng Git Modules

Thêm vào `values.yaml`:

```yaml
openresty:
  modules:
    enabled: true
    gitModules:
      - name: "lua-resty-consul"
        url: "https://github.com/hashicorp/lua-resty-consul.git"
        path: "/usr/local/openresty/lualib/resty/consul"
      - name: "lua-resty-kafka"
        url: "https://github.com/doujiang24/lua-resty-kafka.git"
        path: "/usr/local/openresty/lualib/resty/kafka"
```

### 3. Custom Modules

Tạo file Lua riêng và thêm vào `values.yaml`:

```yaml
openresty:
  lua:
    enabled: true
    scripts:
      my_module.lua: |
        local _M = {}

        function _M.hello()
            return "Hello from custom module!"
        end

        return _M
```

## Sử dụng Modules trong nginx.conf

### 1. Cấu hình Lua Package Path

```nginx
http {
    lua_package_path "/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/custom/?.lua;;";
    lua_package_cpath "/usr/local/openresty/lualib/?.so;;";
}
```

### 2. Sử dụng trong Lua Scripts

```lua
-- Redis example
local redis = require "resty.redis"
local red = redis:new()
red:set_timeout(1000)
local ok, err = red:connect("redis-service", 6379)

-- MySQL example
local mysql = require "resty.mysql"
local db, err = mysql:new()
db:set_timeout(1000)
local ok, err = db:connect{
    host = "mysql-service",
    port = 3306,
    database = "test",
    user = "root",
    password = "password"
}

-- JWT example
local jwt = require "resty.jwt"
local jwt_obj = jwt:verify("your-secret", token)
```

### 3. Sử dụng trong nginx.conf

```nginx
location /api {
    content_by_lua_block {
        local redis = require "resty.redis"
        local red = redis:new()
        red:set_timeout(1000)

        local ok, err = red:connect("redis-service", 6379)
        if not ok then
            ngx.say("failed to connect: ", err)
            return
        end

        local res, err = red:get("key")
        if not res then
            ngx.say("failed to get: ", err)
            return
        end

        ngx.say("Redis value: ", res)
    }
}
```

## Ví dụ sử dụng các Module phổ biến

### 1. Redis Operations

```lua
local redis = require "resty.redis"

local function get_redis_connection()
    local red = redis:new()
    red:set_timeout(1000)

    local ok, err = red:connect("redis-service", 6379)
    if not ok then
        return nil, err
    end

    return red
end

local function get_value(key)
    local red, err = get_redis_connection()
    if not red then
        return nil, err
    end

    local res, err = red:get(key)
    red:close()
    return res, err
end
```

### 2. MySQL Operations

```lua
local mysql = require "resty.mysql"

local function get_mysql_connection()
    local db, err = mysql:new()
    if not db then
        return nil, err
    end

    db:set_timeout(1000)

    local ok, err = db:connect{
        host = "mysql-service",
        port = 3306,
        database = "test",
        user = "root",
        password = "password"
    }
    if not ok then
        return nil, err
    end

    return db
end

local function query(sql)
    local db, err = get_mysql_connection()
    if not db then
        return nil, err
    end

    local res, err = db:query(sql)
    db:close()
    return res, err
end
```

### 3. JWT Operations

```lua
local jwt = require "resty.jwt"

local function verify_jwt(token)
    local jwt_obj = jwt:verify("your-secret", token)
    if jwt_obj.valid then
        return jwt_obj.payload
    else
        return nil, jwt_obj.reason
    end
end

local function create_jwt(payload)
    local jwt_obj = jwt:sign("your-secret", {
        header = {typ = "JWT", alg = "HS256"},
        payload = payload
    })
    return jwt_obj
end
```

### 4. HTTP Client Operations

```lua
local http = require "resty.http"

local function make_request(url, method, headers, body)
    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        method = method,
        headers = headers,
        body = body
    })

    if not res then
        return nil, err
    end

    return res
end
```

## Troubleshooting

### 1. Module không tìm thấy

Kiểm tra `lua_package_path` trong nginx.conf:

```nginx
lua_package_path "/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/custom/?.lua;;";
```

### 2. Module không load được

Kiểm tra quyền truy cập:

```bash
kubectl exec -it <pod-name> -- ls -la /usr/local/openresty/lualib/
```

### 3. Init container fail

Kiểm tra logs của init container:

```bash
kubectl logs <pod-name> -c modules-init
```

### 4. Module version conflict

Sử dụng specific version:

```yaml
luarocks:
  - "lua-resty-redis 0.29"
  - "lua-resty-mysql 0.23"
```

## Best Practices

1. **Sử dụng specific versions** để tránh conflict
2. **Test modules** trước khi deploy production
3. **Monitor resource usage** khi sử dụng nhiều modules
4. **Use connection pooling** cho database modules
5. **Handle errors properly** trong Lua scripts
