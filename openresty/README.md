# OpenResty Helm Chart

Helm chart để deploy OpenResty với hỗ trợ Lua và các tính năng nâng cao.

## Tính năng

- ✅ Service LoadBalancer với annotations tùy chỉnh
- ✅ Hỗ trợ port 80 và 443
- ✅ Horizontal Pod Autoscaler (HPA)
- ✅ Tùy chỉnh image, repository và tag
- ✅ Giới hạn tài nguyên (resource limits)
- ✅ Cấu hình OpenResty tùy chỉnh
- ✅ Hỗ trợ Lua scripts với các module (http, json, socket...)
- ✅ Persistent Volume cho lưu trữ dữ liệu
- ✅ Ingress support
- ✅ Network Policy
- ✅ Pod Disruption Budget

## Cài đặt

### Cài đặt từ local chart

```bash
# Clone hoặc download chart
cd helm-openresty

# Install chart
helm install my-openresty . -n my-namespace

# Hoặc với custom values
helm install my-openresty . -f custom-values.yaml -n my-namespace
```

### Cài đặt với custom values

```bash
helm install my-openresty . \
  --set image.repository=openresty/openresty \
  --set image.tag=1.21.4.1-alpine \
  --set service.type=LoadBalancer \
  --set service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=10 \
  --set resources.limits.cpu=1000m \
  --set resources.limits.memory=1Gi \
  -n my-namespace
```

## Cấu hình

### Cấu hình cơ bản

```yaml
# values.yaml
replicaCount: 1

image:
  repository: openresty/openresty
  tag: "1.21.4.1-alpine"
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80
  targetPort: 80
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
  https:
    enabled: true
    port: 443
    targetPort: 443

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

### Cấu hình OpenResty

```yaml
openresty:
  config:
    enabled: true
    nginxConf: |
      user nginx;
      worker_processes auto;
      error_log /var/log/nginx/error.log warn;
      pid /var/run/nginx.pid;

      events {
          worker_connections 1024;
      }

      http {
          include /etc/nginx/mime.types;
          default_type application/octet-stream;

          server {
              listen 80;
              server_name _;

              location / {
                  root /usr/share/nginx/html;
                  index index.html index.htm;
              }

              location /health {
                  access_log off;
                  return 200 "healthy\n";
                  add_header Content-Type text/plain;
              }
          }
      }
```

### Cấu hình Lua Scripts

```yaml
openresty:
  lua:
    enabled: true
    modules:
      - http
      - json
      - socket
    scripts:
      lazy_cert.lua: |
        local http = require "resty.http"
        local json = require "cjson"

        local function get_cert_from_service(domain)
            local httpc = http.new()
            local res, err = httpc:request_uri("http://cert-service:8080/cert/" .. domain, {
                method = "GET",
                headers = {
                    ["Content-Type"] = "application/json"
                }
            })
            
            if not res then
                ngx.log(ngx.ERR, "failed to request cert service: ", err)
                return nil
            end
            
            if res.status ~= 200 then
                ngx.log(ngx.ERR, "cert service returned status: ", res.status)
                return nil
            end
            
            local cert_data = json.decode(res.body)
            return cert_data.cert, cert_data.key
        end

        _M.get_cert_from_service = get_cert_from_service
        return _M
```

### Cấu hình Persistent Volume

```yaml
persistence:
  enabled: true
  accessMode: ReadWriteOnce
  size: 1Gi
  storageClass: "gp2"
```

### Cấu hình HPA

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

## Sử dụng

### Kiểm tra deployment

```bash
# Kiểm tra pods
kubectl get pods -l app.kubernetes.io/name=openresty

# Kiểm tra service
kubectl get svc -l app.kubernetes.io/name=openresty

# Kiểm tra logs
kubectl logs -l app.kubernetes.io/name=openresty
```

### Health check

```bash
# Lấy service IP
SERVICE_IP=$(kubectl get svc my-openresty -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Health check
curl http://$SERVICE_IP/health
```

### Cập nhật cấu hình

```bash
# Cập nhật values
helm upgrade my-openresty . -f new-values.yaml

# Cập nhật chỉ một giá trị
helm upgrade my-openresty . --set image.tag=1.21.4.2-alpine
```

## Troubleshooting

### Kiểm tra ConfigMap

```bash
kubectl get configmap my-openresty-config -o yaml
kubectl get configmap my-openresty-lua -o yaml
```

### Kiểm tra PVC

```bash
kubectl get pvc my-openresty-pvc
kubectl describe pvc my-openresty-pvc
```

### Debug pods

```bash
kubectl exec -it <pod-name> -- /bin/sh
```

## Uninstall

```bash
helm uninstall my-openresty -n my-namespace
```

## Tham khảo

- [OpenResty Documentation](https://openresty.org/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
