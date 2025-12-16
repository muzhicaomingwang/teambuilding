# 架构设计 - 团建助手 (Architecture Design - Team Building Assistant)

**架构专家输出文档**

## 1. 架构概览 (Architecture Overview)

基于DDD领域驱动设计原则，本系统采用微服务架构模式，每个限界上下文对应一个独立的微服务。架构设计遵循以下核心原则：

- **领域中心**: 以业务领域为核心组织代码和服务
- **松耦合**: 服务之间通过定义良好的接口进行交互
- **高内聚**: 每个服务专注于特定业务领域
- **数据自治**: 每个服务拥有自己的数据存储
- **事件驱动**: 通过领域事件实现服务间通信

## 2. 限界上下文间架构 (Inter-Context Architecture)

### 2.1 总体架构图
```
┌─────────────────────────────────────────────────────────────┐
│                         API Gateway                         │
│                     (统一入口，路由分发)                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────┼───────────────────────────────────────┐
│          Event Bus  │  (事件总线，异步通信)                   │
│                     ▼                                       │
│  ┌─────────────────────┐    ┌─────────────────────┐        │
│  │ Activity Planning   │    │ Budget Management   │        │
│  │     Context         │    │     Context         │        │
│  └──────────┬──────────┘    └──────────┬──────────┘        │
│             │                           │                   │
│             ▼                           ▼                   │
│  ┌─────────────────────┐    ┌─────────────────────┐        │
│  │ Team Coordination   │    │ Feedback Analytics  │        │
│  │     Context         │    │     Context         │        │
│  └──────────┬──────────┘    └──────────┬──────────┘        │
│             │                           │                   │
│             └───────────┬───────────────┘                   │
│                         ▼                                   │
│              ┌─────────────────────┐                        │
│              │  Media Sharing      │                        │
│              │     Context         │                        │
│              └──────────┬──────────┘                        │
│                         │                                 │
│                         ▼                                 │
│              ┌─────────────────────┐                        │
│              │   Scheduling        │                        │
│              │     Context         │                        │
│              └─────────────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 上下文映射模式 (Context Mapping Patterns)

#### 2.2.1 共享内核模式 (Shared Kernel)
**参与者**: 活动规划上下文 ↔ 团队协调上下文
- **共享模型**:
  - `TeamProfile`: 团队画像信息
  - `MemberProfile`: 成员基本信息
- **同步策略**: 通过共享数据库表或API同步
- **责任分工**: 活动规划负责分析，团队协调负责维护

#### 2.2.2 客户-供应商模式 (Customer-Supplier)
**示例**: 活动规划上下文 (客户) ↔ 预算管理上下文 (供应商)
- **客户权利**: 要求预算管理提供准确的成本估算
- **供应商责任**: 及时响应预算查询，保证数据准确性
- **契约定义**:
```yaml
# 预算查询API契约
POST /api/budget/estimate
Request:
  activityType: "OUTDOOR_TEAM_BUILDING"
  participantCount: 50
  duration: "ONE_DAY"
  location: "OUTDOOR_PARK"
Response:
  minBudget: 15000
  maxBudget: 25000
  breakdown:
    - category: "VENUE"
      amount: 5000
    - category: "CATERING"
      amount: 8000
```

#### 2.2.3 遵从者模式 (Conformist)
**参与者**: 团队协调上下文 → 日程管理上下文
- **依赖关系**: 团队协调完全遵循日程管理的时间规则
- **接口适配**: 无需转换，直接使用

#### 2.2.4 防腐层模式 (Anti-Corruption Layer)
**参与者**: 预算管理上下文 ↔ 媒体分享上下文
- **防腐层位置**: 在预算管理上下文中
- **隔离内容**: 防止预算规则影响分享功能的简单性
- **实现方式**: 通过适配器模式

```java
// 防腐层适配器示例
@Component
public class BudgetToMediaAdapter {

    public SharingPermission createSharingPermission(Budget budget) {
        // 提取预算相关信息，转换为权限设置
        SharingPermission permission = new SharingPermission();

        if (budget.hasExceeded()) {
            permission.setMaxFileSize(10); // MB
        } else {
            permission.setMaxFileSize(50); // MB
        }

        return permission;
    }
}
```

## 3. 限界上下文内架构 (Intra-Context Architecture)

### 3.1 六边形架构 (Hexagonal Architecture)

每个限界上下文采用六边形架构，实现核心业务逻辑与外部依赖的解耦：

```
┌─────────────────────┐
│   Presentation      │  <-- UI/Web/API层
├─────────────────────┤
│   Application       │  <-- 应用服务层
├─────────────────────┤
│   Domain            │  <-- 领域层 (核心业务)
│   ├─ Services       │
│   ├─ Entities       │
│   ├─ Value Objects  │
│   └─ Domain Events  │
├─────────────────────┤
│   Infrastructure    │  <-- 基础设施层
│   ├─ Repository     │
│   ├─ External API   │
│   └─ Messaging      │
└─────────────────────┘
```

### 3.2 分层架构细节 (Layered Architecture Details)

#### 3.2.1 表示层 (Presentation Layer)
```yaml
API设计原则:
  - RESTful风格
  - 使用OpenAPI 3.0规范
  - 统一响应格式
  - 版本控制 (/v1/, /v2/)

统一响应格式:
  code: 200
  message: "success"
  data: {}
  timestamp: "2024-01-01T12:00:00Z"
  traceId: "uuid-12345"
```

#### 3.2.2 应用服务层 (Application Service Layer)
- **职责**: 编排业务流程，不包含业务规则
- **模式**: CQRS (命令查询职责分离)
- **事务边界**: 每个用例一个事务
- **事件发布**: 在业务操作成功后发布领域事件

#### 3.2.3 领域层 (Domain Layer)
- **实体**: 具有唯一标识和生命周期的对象
- **值对象**: 不需要唯一标识的不可变对象
- **领域服务**: 处理跨多个实体的业务逻辑
- **领域事件**: 记录重要的业务动作

#### 3.2.4 基础设施层 (Infrastructure Layer)
- **仓库**: 数据持久化
- **防腐层**: 隔离外部系统
- **消息队列**: 异步通信
- **缓存**: 提高性能

## 4. 通信架构 (Communication Architecture)

### 4.1 同步通信 (Synchronous Communication)

#### 4.1.1 HTTP REST API
适用于实时性要求高的交互：
- 查询团队信息
- 获取预算详情
- 检查活动状态

#### 4.1.2 gRPC API
适用于服务间高效通信：
```protobuf
// activity_planning.proto
service ActivityPlanningService {
  rpc GetActivityDetails(GetActivityRequest) returns (ActivityResponse);
  rpc ReserveActivity(ReservationRequest) returns (ReservationResponse);
  rpc CancelActivity(CancellationRequest) returns (CancellationResponse);
}
```

### 4.2 异步通信 (Asynchronous Communication)

#### 4.2.1 事件总线 (Event Bus)
使用Apache Kafka作为中心事件总线：

```yaml
Kafka Topics配置:
  activity-events:
    partitions: 6
    replication-factor: 3
    retention: 7 days

  budget-events:
    partitions: 3
    replication-factor: 3
    retention: 14 days

  team-events:
    partitions: 9
    replication-factor: 3
    retention: 30 days
```

#### 4.2.2 事件结构标准 (Event Schema)
```json
{
  "metadata": {
    "eventId": "uuid-v4",
    "eventType": "ActivityCreated",
    "timestamp": "2024-01-01T12:00:00Z",
    "version": "1.0",
    "source": "activity-planning-service"
  },
  "payload": {
    "activityId": "activity-123",
    "teamId": "team-456",
    "budgetId": "budget-789",
    "details": {
      "type": "OUTDOOR_TEAM_BUILDING",
      "estimatedBudget": 50000,
      "scheduledDate": "2024-02-01",
      "participantCount": 100
    }
  }
}
```

### 4.3 服务发现 (Service Discovery)
采用Consul作为服务注册中心：

```yaml
Service Registration配置:
  consul:
    host: consul-server:8500
    service:
      id: activity-planning-001
      name: activity-planning
      tags:
        - v1
        - prod
      check:
        http: http://host:8080/health
        interval: 30s
        timeout: 5s
```

## 5. 数据架构 (Data Architecture)

### 5.1 数据所有权 (Data Ownership)
采用数据库-per-service模式：

| 服务 | 数据库 | 数据类型 |
|------|--------|----------|
| Activity Planning | PostgreSQL | 活动数据、推荐算法 |
| Budget Management | MySQL | 预算、成本数据 |
| Team Coordination | PostgreSQL | 成员、分组数据 |
| Feedback Analytics | ElasticSearch | 反馈、分析数据 |
| Media Sharing | MongoDB | 照片、视频元数据 |
| Scheduling | PostgreSQL | 时间、日程数据 |

### 5.2 数据一致性 (Data Consistency)

#### 5.2.1 最终一致性 (Eventual Consistency)
通过事件溯源实现跨服务数据同步：

```yaml
示例: 活动创建后更新预算服务
1. 活动规划服务发布"ActivityCreated"事件
2. 预算服务消费事件，更新预算使用率
3. 反馈服务记录活动创建历史
4. 通知服务发送确认通知
```

#### 5.2.2 Saga模式 (Saga Pattern)
处理跨服务的长事务：

```java
// 活动创建Saga
public class ActivityCreationSaga {

    private enum State {
        PLANNING_STARTED,
        BUDGET_RESERVED,
        TEAM_NOTIFIED,
        SCHEDULE_CONFIRMED,
        ACTIVITY_CREATED
    }

    @EventListener
    public void handle(PlanningStartedEvent event) {
        // 1. 预留预算
        budgetService.reserveBudget(event.getBudgetId());
    }

    @EventListener
    public void handle(BudgetReservedEvent event) {
        // 2. 通知团队
        notificationService.notifyTeam(event.getTeamId());
    }

    // ... 继续处理后续步骤

    @EventListener
    public void handle(ScheduleConflictedEvent event) {
        // 补偿流程：释放预算、通知失败
        budgetService.releaseBudget(event.getBudgetId());
        notificationService.notifyPlanningFailure(event.getActivityId());
    }
}
```

## 6. 安全架构 (Security Architecture)

### 6.1 认证授权 (Authentication & Authorization)
采用OAuth 2.0 + JWT方案：

```yaml
Security Flow:
  1. 用户登录获取JWT Token
  2. API Gateway验证Token签名
  3. 提取用户角色和权限
  4. 根据权限决定是否转发请求
  5. 服务间调用使用Service Account Token
```

### 6.2 数据保护 (Data Protection)
- **传输中**: 使用TLS 1.3加密所有通信
- **静态数据**: 敏感数据AES-256加密
- **个人信息**: 符合GDPR要求，可审计删除
- **支付信息**: 遵循PCI DSS标准

### 6.3 服务间认证 (Service-to-Service Authentication)
使用mTLS（Mutual TLS）：

```yaml
mTLS配置:
  cert-manager:
    issuer:
      ca: team-building-ca
      keySize: 4096
      duration: 8760h # 1 year
    certificates:
      - name: activity-planning-cert
        usages:
          - "server auth"
          - "client auth"
        dnsNames:
          - activity-planning.team-building.local
```

## 7. 性能架构 (Performance Architecture)

### 7.1 缓存策略 (Caching Strategy)

#### 7.1.1 多级缓存 (Multi-Level Caching)
```
L1 - Application Cache (In-Memory)
├─ User Session Cache (5 min TTL)
├─ Activity Template Cache (1 hour TTL)
└─ Static Reference Data (24 hour TTL)

L2 - Distributed Cache (Redis)
├─ Hot Activity Cache (15 min TTL)
├─ Team Authorization Cache (30 min TTL)
└─ Budget Status Cache (5 min TTL)
```

#### 7.1.2 缓存更新策略 (Cache Update Strategies)
- **Write-Through**: 数据写入时同时更新缓存
- **Write-Behind**: 异步更新缓存以提高写入性能
- **Refresh-Ahead**: 提前刷新即将过期的缓存

### 7.2 负载均衡 (Load Balancing)
```yaml
Traffic Distribution:
  1. Global:
     - Route 53 (Geo-based)
     - Different regions: APAC, EMEA, Americas

  2. Regional:
     - Application Load Balancer
     - Weighted target groups (EVEN: 50-50)

  3. Service Level:
     - Envoy Proxy with circuit breaking
     - Retry policy: 3 attempts, exponential backoff
```

### 7.3 数据库优化 (Database Optimization)

#### 7.3.1 读写分离 (Read/Write Splitting)
```yaml
Database Routing:
  Write Operations:
    - CREATE/UPDATE/DELETE
    - Routed to primary
    - Strong consistency required

  Read Operations:
    - SELECT queries
    - Routed to read replicas
    - Eventual consistency acceptable
```

#### 7.3.2 分库分表 (Sharding)
```yaml
Sharding Strategy:
  Activity Table:
    - Shard Key: teamId
    - Shard Count: 16
    - Shard Function: hash(teamId) mod 16

  Feedback Table:
    - Shard Key: activityId
    - Shard Count: 8
    - Time-based: Monthly partitions
```

## 8. 监控架构 (Monitoring Architecture)

### 8.1 日志聚合 (Log Aggregation)
采用ELK Stack（ElasticSearch + Logstash + Kibana）：

```yaml
Logging Best Practices:
  1. Structured Logging:
     {"timestamp":"ISO-8601","level":"INFO","service":"activity-planning","traceId":"uuid","message":"Activity created","context":{"activityId":"123","teamId":"456"}}

  2. Correlation ID:
     - Generate at API Gateway
     - Pass through all service calls
     - Include in all log entries

  3. Log Levels by Environment:
     - DEBUG: dev
     - INFO: staging
     - WARN/ERROR: prod
```

### 8.2 度量指标 (Metrics)
采用Prometheus + Grafana方案：

```yaml
Key Metrics:
  1. Application Metrics:
     - Request Rate (req/s)
     - Error Rate (%)
     - Response Time (p50, p95, p99)
     - Active Connections

  2. Business Metrics:
     - Activity Creation Rate
     - Successful Events vs Failed
     - Budget Utilization
     - Feedback Submission Rate

  3. Infrastructure Metrics:
     - CPU Utilization
     - Memory Usage
     - Disk I/O
     - Network Bandwidth
```

### 8.3 链路追踪 (Distributed Tracing)
使用Jaeger进行分布式追踪：

```yaml
Trace Configuration:
  sampler:
    type: probabilistic
    probability: 0.1 # 采样率10%

  storage:
    type: elasticsearch
    spanStorageType: elasticsearch
    maxSpanAge: 168h # 7 days

追踪的关键路径:
  - Activity Creation Flow
  - Budget Approval Flow
  - Member Confirmation Flow
  - Feedback Aggregation Flow
```

## 9. 部署架构 (Deployment Architecture)

### 9.1 容器化部署 (Container Deployment)
使用Kubernetes进行容器编排：

```yaml
Pod Template示例:
apiVersion: apps/v1
kind: Deployment
metadata:
  name: activity-planning-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: activity-planning
  template:
    metadata:
      labels:
        app: activity-planning
        version: v1.0.0
    spec:
      containers:
      - name: activity-planning
        image: team-building/activity-planning:latest
        ports:
        - containerPort: 8080
        env:
        - name: DB_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
```

### 9.2 服务网格 (Service Mesh)
使用Istio进行服务间通信管理：

```yaml
Istio配置:
  1. 流量管理:
     - Circuit Breaking: 连续失败5次触发
     - Retry Policy: 3次重试，间隔指数增长
     - Timeout: 上游服务30秒超时

  2. 安全策略:
     - mTLS: 所有服务间通信加密
     - Authorization Policy: 基于角色的访问控制

  3. 可观测性:
     - Metrics: Prometheus集成
     - Traces: Jaeger集成
     - Logs: Fluentd集成
```

## 10. 总结 (Summary)

本架构设计基于DDD的原则，构建了一个松耦合、高内聚的微服务架构。各限界上下文作为独立服务，通过明确定义的接口进行通信。事件驱动的架构确保了系统的可扩展性和可维护性。多层缓存、负载均衡和监控体系保证了系统的稳定性和可用性。下一步，技术专家将基于此架构设计制定具体的技术选型和实现方案。\n\n**关键决策总结**:
1. 微服务架构，每上下文一服务
2. 事件驱动，Kafka作为消息总线
3. 数据库-per-service，保证数据自治
4. 六边形架构，领域逻辑独立
5. 多级缓存，确保高性能
6. 全面监控，保证可观测性
\n**下一步**: 技术专家将基于此架构设计，选择具体技术栈并制定详细的技术实施方案。\n\n---

**生成日期**: 2024年\n**架构专家**: [虚拟角色输出]\n**评审状态**: 待技术专家评审