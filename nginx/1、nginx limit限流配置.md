## Nginx limit限流配置

### 根据IP限制访问频率

```shell
http {
    limit_req_zone $binary_remote_addr zone=one:10m rate=5r/m;
    ...
}
#限制相同remote address访问频率每分钟5次

server {
   ...
   location /campaign/voters {
        limit_req zone=one burst=5 nodelay;
        proxy_pass http://172.20.30.202:8100;
   }

}
#如果超过访问频次限制的请求，可以先放到这个缓冲区里，如果缓冲区也满了，则返回503
```

测试：



