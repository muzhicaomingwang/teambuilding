# 团建助手项目 Prometheus 监控体系设计方案

## 一、项目监控需求分析

### 1.1 项目架构概述
团建助手项目采用微服务架构，包含以下核心服务：
- **前端服务**: React + Vite 单页应用
- **后端API服务**: Spring Boot 微服务集群
- **AI推荐服务**: 集成 Claude API 的智能推荐引擎
- **数据库**: PostgreSQL 主从集群
- **缓存服务**: Redis 集群
- **文件存储**: 阿里云OSS/S3

### 1.2 监控目标
- **业务指标**: 用户活跃度、活动创建率、AI推荐准确率等
- **技术指标**: 服务健康状态、响应时间、资源使用率等
- **基础设施**: K8s集群、节点状态、网络流量等

## 二、Prometheus 核心特性与优势

### 2.1 核心特性（2025版）
- **多维数据模型**: 基于时间序列的指标数据，支持灵活的标签查询
- **强大的查询语言**: PromQL 支持复杂的数据聚合和分析
- **云原生集成**: 深度支持 Kubernetes，自动服务发现
- **高效存储**: 本地TSDB优化，支持远程存储集成
- **丰富的生态**: 800+ Exporter，完善的开源生态

### 2.2 2025年新特性
- OpenTelemetry 原生直方图无缝转换
- K8s EndpointSlice 发现效率提升40%
- 支持 duration 算术运算和 histogram_fraction
- 查询性能优化，6亿数据点查询8-10秒完成

## 三、整体监控架构设计

### 3.1 架构图
```
┌─────────────────────────────────────────────────────────────────┐
│                        监控数据流                                │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   业务层     │  │   应用层     │  │  基础设施层   │             │
│  │             │  │             │  │             │             │
│  │ - 用户指标   │  │ - API指标    │  │ - K8s集群    │             │
│  │ - 业务KPI    │  │ - JVM指标    │  │ - 节点状态   │             │
│  │ - 推荐准确率 │  │ - 响应时间   │  │ - 网络流量   │             │
│  └─────┬───────┘  └─────┬───────┘  └─────┬───────┘             │
│        │              │              │                       │
│        └──────────────┼──────────────┘                       │
│                       │                                        │
│              ┌────────▼────────┐                              │
│              │  Prometheus     │                              │
│              │   主实例        │                              │
│              └────────┬────────┘                              │
│                       │                                        │
│              ┌────────▼────────┐     ┌──────────┐            │
│              │   Thanos        │────▶│ 对象存储  │            │
│              │  长期存储       │     │ (S3/OSS) │            │
│              └─────────────────┘     └──────────┘            │
│                       │                                        │
│              ┌────────▼────────┐                              │
│              │  Alertmanager   │                              │
│              │   告警管理      │                              │
│              └────────┬────────┘                              │
│                       │                                        │
│        ┌──────────────┼──────────────┐                       │
│        ▼              ▼              ▼                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │  Grafana │  │ 钉钉/飞书 │  │  邮件通知  │                  │
│  │  可视化   │  │   即时通知 │  │          │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 部署模式选择
采用 **Thanos + Prometheus** 架构，提供：
- 高可用性：双活 Prometheus 实例
- 数据去重：Thanos Query 层自动去重
- 长期存储：数据持久化到云端对象存储
- 全局视图：跨集群统一查询

## 四、监控指标定义

### 4.1 业务指标（Business Metrics）

#### 核心业务指标
- **用户注册转化率**: 新注册用户数/访问用户数
- **活动创建成功率**: 成功创建活动数/总创建请求数
- **活动完成率**: 已完成活动数/总创建活动数
- **AI推荐准确率**: 用户采纳推荐数/总推荐数
- **用户留存率**: 7日/30日留存用户比例

#### 运营指标
- **日活跃用户(DAU)**: 每日登录用户数
- **月活跃用户(MAU)**: 每月登录用户数
- **平均会话时长**: 用户单次使用时长
- **功能使用频率**: 各功能模块的使用统计

### 4.2 技术指标（Technical Metrics）

#### 应用层指标
```yaml
# HTTP 请求指标
http_requests_total{method, status, endpoint}
http_request_duration_seconds{method, status, endpoint}
http_request_size_bytes{method, endpoint}
http_response_size_bytes{method, endpoint}

# JVM 指标（Spring Boot）
jvm_memory_used_bytes{area}
jvm_memory_max_bytes{area}
jvm_gc_pause_seconds_sum{gc}
jvm_threads_current{}
jvm_classes_loaded{}

# 数据库连接池
hikaricp_connections_active{pool}
hikaricp_connections_idle{pool}
hikaricp_connections_timeout_total{pool}

# 自定义业务指标
activity_created_total{status, type}
user_registered_total{source}
ai_recommendation_total{result, confidence}
```

#### 基础设施指标
```yaml
# Kubernetes 集群
kube_node_status_condition{condition, status}
kube_pod_container_status_restarts_total{namespace, pod, container}
kube_deployment_status_replicas_available{deployment, namespace}
kube_deployment_spec_replicas{deployment, namespace}

# 节点资源
node_cpu_utilization{node, cpu}
node_memory_utilization{node}
node_disk_io_utilization{node, device}
node_network_receive_bytes_total{node, interface}

# 存储资源
storage_capacity_bytes{volume}
storage_available_bytes{volume}
storage_usage_percentage{volume}
```

## 五、监控部署架构

### 5.1 部署组件

#### 核心组件
```yaml
# Prometheus Server（双实例）
image: prom/prometheus:v3.4.0
resources:
  requests:
    cpu: 2000m
    memory: 8Gi
  limits:
    cpu: 4000m
    memory: 16Gi
retention: 7d
storage: 500GB SSD

# Thanos Sidecar
image: quay.io/thanos/thanos:v0.35.1
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 1000m
    memory: 2Gi

# Thanos Store
image: quay.io/thanos/thanos:v0.35.1
resources:
  requests:
    cpu: 1000m
    memory: 4Gi
  limits:
    cpu: 2000m
    memory: 8Gi

# Alertmanager
image: prom/alertmanager:v0.27.0
replicas: 3
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

### 5.2 采集配置

#### ServiceMonitor 配置
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: team-building-api
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: team-building-api
  endpoints:
  - port: metrics
    interval: 30s
    path: /actuator/prometheus
    relabelings:
    - sourceLabels: [__meta_kubernetes_pod_name]
      targetLabel: pod
    - sourceLabels: [__meta_kubernetes_namespace]
      targetLabel: namespace
```

#### PodMonitor 配置
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: ai-recommendation-service
spec:
  selector:
    matchLabels:
      app: ai-recommendation
  podMetricsEndpoints:
  - port: metrics
    interval: 15s
    path: /metrics
```

## 六、告警规则设计

### 6.1 业务告警

#### 关键业务告警
```yaml
groups:
- name: business_rules
  rules:
  - alert: HighRegistrationFailureRate
    expr: |
      (rate(user_registered_total{status="failed"}[5m]) /
       rate(user_registered_total[5m])) > 0.05
    for: 5m
    labels:
      severity: critical
      team: business
    annotations:
      summary: "用户注册失败率超过5%"
      description: "过去5分钟用户注册失败率为 {{ $value | humanizePercentage }}"

  - alert: LowActivityCompletionRate
    expr: |
      (rate(activity_created_total{status="completed"}[1h]) /
       rate(activity_created_total[1h])) < 0.3
    for: 15m
    labels:
      severity: warning
      team: business
    annotations:
      summary: "活动完成率低于30%"
      description: "过去1小时活动完成率仅为 {{ $value | humanizePercentage }}"
```

#### AI服务质量告警
```yaml
  - alert: AIRecommendationAccuracy
    expr: |
      (rate(ai_recommendation_total{result="accepted"}[1h]) /
       rate(ai_recommendation_total[1h])) < 0.6
    for: 10m
    labels:
      severity: warning
      team: ai
    annotations:
      summary: "AI推荐准确率低于60%"
      description: "当前推荐准确率: {{ $value | humanizePercentage }}"

  - alert: AIRecommendationLatency
    expr: |
      histogram_quantile(0.95,
        rate(ai_recommendation_duration_seconds_bucket[5m])) > 5
    for: 3m
    labels:
      severity: critical
      team: ai
    annotations:
      summary: "AI推荐响应时间P95超过5秒"
      description: "95%请求响应时间: {{ $value }}s"
```

### 6.2 技术告警

#### 应用性能告警
```yaml
- name: application_rules
  rules:
  - alert: HighErrorRate
    expr: |
      (rate(http_requests_total{status=~"5.."}[5m]) /
       rate(http_requests_total[5m])) > 0.01
    for: 5m
    labels:
      severity: critical
      team: backend
    annotations:
      summary: "API错误率超过1%"
      description: "服务 {{ $labels.endpoint }} 错误率 {{ $value | humanizePercentage }}"

  - alert: HighLatency
    expr: |
      histogram_quantile(0.95,
        rate(http_request_duration_seconds_bucket[5m])) > 0.5
    for: 5m
    labels:
      severity: warning
      team: backend
    annotations:
      summary: "API响应时间P95超过500ms"
      description: "{{ $labels.endpoint }} P95延迟: {{ $value }}s"
```

#### 资源使用告警
```yaml
  - alert: HighMemoryUsage
    expr: |
      (process_resident_memory_bytes /
       container_spec_memory_limit_bytes) > 0.9
    for: 10m
    labels:
      severity: warning
      team: ops
    annotations:
      summary: "容器内存使用率超过90%"
      description: "Pod {{ $labels.pod }} 内存使用率: {{ $value | humanizePercentage }}"

  - alert: PodCrashLooping
    expr: |
      rate(kube_pod_container_status_restarts_total[15m]) > 0.1
    for: 10m
    labels:
      severity: critical
      team: ops
    annotations:
      summary: "Pod频繁重启"
      description: "{{ $labels.namespace }}/{{ $labels.pod }} 15分钟内重启 {{ $value }} 次"
```

## 七、通知机制

### 7.1 通知配置
```yaml
global:
  resolve_timeout: 5m
  smtp_from: 'alertmanager@team-building.com'
  smtp_smarthost: 'smtp.qiye.aliyun.com:465'
  smtp_auth_username: 'alertmanager@team-building.com'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'default'
  routes:
  - match:
      severity: critical
    receiver: critical-alerts
    continue: true
  - match:
      alertname: HighRegistrationFailureRate
    receiver: business-team
    group_wait: 30s

receivers:
- name: 'default'
  webhook_configs:
  - url: 'http://webhook-server/webhook'
    send_resolved: true

- name: 'critical-alerts'
  email_configs:
  - to: 'oncall@team-building.com'
    subject: '[CRITICAL] {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      Labels: {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
      {{ end }}
  webhook_configs:
  - url: 'https://oapi.dingtalk.com/robot/send?access_token=TOKEN'
    send_resolved: true
    title: '{{ .GroupLabels.alertname }}'
    text: |
      # 🚨 严重告警
      {{ range .Alerts }}
      **{{ .Annotations.summary }}**
      {{ .Annotations.description }}
      时间: {{ .StartsAt.Format "2006-01-02 15:04:05" }}
      {{ end }}

- name: 'business-team'
  email_configs:
  - to: 'business@team-building.com'
    subject: '[业务告警] {{ .GroupLabels.alertname }}'
```

### 7.2 告警分级策略

| 级别 | 响应时间 | 通知方式 | 处理团队 |
|------|----------|----------|----------|
| Critical | 5分钟 | 电话+短信+邮件+钉钉 | 运维+开发 |
| Warning | 30分钟 | 邮件+钉钉 | 开发 |
| Info | 2小时 | 邮件 | 业务 |

## 八、高可用和扩展性

### 8.1 高可用架构
```
┌─────────────────┐     ┌─────────────────┐
│   Prometheus    │     │   Prometheus    │
│   Instance-1    │     │   Instance-2    │
│    (Active)     │     │   (Standby)     │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────┬───────────────┘
                 │
         ┌───────▼────────┐
         │   Thanos       │
         │   Query        │
         └────────┬───────┘
                  │
    ┌─────────────┼─────────────┐
    ▼             ▼             ▼
┌────────┐  ┌────────┐  ┌────────┐
│Storage │  │Store   │  │Compact │
│Gateway │  │Gateway │  │        │
└────────┘  └────────┘  └────────┘
```

### 8.2 数据备份与恢复
- 每日自动备份到云端对象存储
- 保留策略：本地7天，云端90天
- 支持时间点恢复功能

### 8.3 扩展策略
- **水平扩展**：通过 Thanos 实现 Prometheus 集群化
- **分片策略**：按业务域或时间分片
- **存储扩展**：支持对象存储无限扩展
- **查询扩展**：Thanos Query 支持并发查询

## 九、资源配置与成本估算

### 9.1 资源需求

| 组件 | CPU | 内存 | 存储 | 实例数 |
|------|-----|------|------|--------|
| Prometheus | 4核 | 16GB | 500GB SSD | 2 |
| Thanos Sidecar | 1核 | 2GB | - | 2 |
| Thanos Store | 2核 | 8GB | - | 2 |
| Thanos Query | 2核 | 4GB | - | 2 |
| Alertmanager | 1核 | 1GB | 10GB | 3 |
| Grafana | 2核 | 4GB | 50GB | 2 |
| Exporters | 0.5核 | 512MB | - | 每节点1个 |

### 9.2 成本估算（月度）

| 项目 | 配置 | 单价 | 数量 | 小计 |
|------|------|------|------|------|
| 计算资源 | 16核64GB | ¥800/月 | 11台 | ¥8,800 |
| 存储资源 | SSD 1TB | ¥500/月 | 2TB | ¥1,000 |
| 对象存储 | 10TB | ¥120/月 | 10TB | ¥1,200 |
| 网络流量 | 10TB | ¥800/月 | 1 | ¥800 |
| **总计** | | | | **¥11,800/月** |

## 十、运维复杂度评估

### 10.1 运维等级划分
- **L1基础运维**: 监控状态检查、告警响应
- **L2中级运维**: 配置调整、性能优化
- **L3高级运维**: 架构调整、故障排查

### 10.2 人力投入

| 任务 | 频率 | 耗时 | 人员要求 |
|------|------|------|----------|
| 日常巡检 | 每日 | 30分钟 | L1 |
| 告警处理 | 按需 | 平均2小时/次 | L1/L2 |
| 规则优化 | 每周 | 2小时 | L2 |
| 性能调优 | 每月 | 4小时 | L3 |
| 版本升级 | 季度 | 8小时 | L3 |

### 10.3 自动化程度
- **90%**: 使用 Operator 自动化部署
- **80%**: 告警规则自动测试
- **70%**: 故障自愈能力
- **95%**: 配置即代码（GitOps）

## 十一、实施路线图

### 阶段1：基础监控搭建（第1周）
1. 部署 Prometheus + Grafana 基础组件
2. 配置基础采集规则
3. 创建基础监控大盘

### 阶段2：业务监控完善（第2-3周）
1. 集成应用层指标
2. 创建业务KPI大盘
3. 配置核心业务告警

### 阶段3：高可用升级（第4周）
1. 部署 Thanos 架构
2. 实现数据持久化
3. 配置告警通知

### 阶段4：优化提升（第5-6周）
1. 性能调优
2. 告警治理
3. 自动化运维

## 十二、总结

本监控方案为团建助手项目提供了：

✅ **完整的监控覆盖**: 从基础设施到业务指标的全面监控
✅ **高可用架构**: 通过 Thanos 实现双活和数据持久化
✅ **智能告警**: 基于SLO的告警策略，减少误报
✅ **成本优化**: 云原生架构，资源按需扩展
✅ **运维友好**: 自动化程度高，降低运维成本

预计实施完成后，将实现：
- 故障发现时间缩短至5分钟内
- 业务关键指标可视化率达到100%
- 告警准确率提升至95%以上
- 年度可用性达到99.9%

---

**参考资料**:
- [Prometheus 2025运维监控系统选型指南](https://cloud.tencent.com/developer/article/2571372)
- [微服务Prometheus监控最佳实践](https://cloud.baidu.com/article/4067178)
- [Prometheus告警规则最佳实践](https://help.aliyun.com/zh/ack/ack-managed-and-ack-dedicated/user-guide/best-practices-for-configuring-alert-rules-in-prometheus)