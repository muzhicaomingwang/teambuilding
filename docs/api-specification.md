# 团建助手API规范 v1.0

## 概述
本文档定义了团建助手系统第一版API规范，严格按照RESTful设计原则，支持MVP阶段所有核心功能。

## 基础信息

### 协议和主机
```
协议: HTTPS
开发环境: https://api-dev.team-building.com
测试环境: https://api-test.team-building.com
生产环境: https://api.team-building.com
```

### 认证方式
采用JWT Bearer Token认证机制：
```http
Authorization: Bearer <jwt_token>
```

### 通用响应格式
```json
{
  "success": true,
  "data": {},
  "message": "操作成功",
  "code": 200,
  "timestamp": "2024-01-15T10:30:00Z",
  "requestId": "req_1234567890"
}
```

错误响应：
```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "AUTH_INVALID_TOKEN",
    "message": "无效的访问令牌",
    "details": {}
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "requestId": "req_1234567890"
}
```

## 用户认证 API

### 1. 用户注册
**POST** `/api/v1/auth/register`

**请求参数：**
```json
{
  "email": "alice@company.com",
  "password": "securePass123",
  "fullName": "张三",
  "organization": "腾讯科技"
}
```

**响应示例：**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "usr_1234567890",
      "email": "alice@company.com",
      "fullName": "张三",
      "organization": "腾讯科技",
      "role": "USER",
      "isActive": true,
      "createdAt": "2024-01-15T10:30:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "注册成功"
}
```

### 2. 用户登录
**POST** `/api/v1/auth/login`

**请求参数：**
```json
{
  "email": "alice@company.com",
  "password": "securePass123",
  "rememberMe": true
}
```

**响应示例：**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "usr_1234567890",
      "email": "alice@company.com",
      "fullName": "张三",
      "role": "USER"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 1800
  },
  "message": "登录成功"
}
```

### 3. 刷新访问令牌
**POST** `/api/v1/auth/refresh`

**请求Header：**
```http
Authorization: Bearer <refresh_token>
```

**响应示例：**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 1800
  }
}
```

### 4. 用户登出
**POST** `/api/v1/auth/logout`

**响应示例：**
```json
{
  "success": true,
  "message": "登出成功"
}
```

## 团队管理 API

### 1. 创建团队
**POST** `/api/v1/teams`

**请求参数：**
```json
{
  "name": "产品研发部",
  "description": "负责核心产品开发的团队",
  "organization": "腾讯科技"
}
```

### 2. 获取团队列表
**GET** `/api/v1/teams?page=1&size=20&sort=-createdAt`

**响应示例：**
```json
{
  "success": true,
  "data": {
    "teams": [
      {
        "id": "team_1234567890",
        "name": "产品研发部",
        "description": "负责核心产品开发的团队",
        "organization": "腾讯科技",
        "ownerId": "usr_1234567890",
        "memberCount": 15,
        "createdAt": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "total": 50,
      "pages": 3
    }
  }
}
```

### 3. 添加团队成员
**POST** `/api/v1/teams/{teamId}/members`

**请求参数：**
```json
{
  "email": "bob@company.com",
  "role": "MEMBER"
}
```

### 4. 移除团队成员
**DELETE** `/api/v1/teams/{teamId}/members/{userId}`

## 活动管理 API

### 1. 创建活动
**POST** `/api/v1/activities`

**请求参数：**
```json
{
  "title": "户外团建烧烤",
  "description": "组织团队户外烧烤活动，增进团队感情",
  "type": "OUTDOOR",
  "teamId": "team_1234567890",
  "minParticipants": 10,
  "maxParticipants": 30,
  "budgetMin": 2000,
  "budgetMax": 5000,
  "location": "深圳大梅沙海滨公园",
  "scheduledDate": "2024-02-15",
  "startTime": "10:00",
  "durationMinutes": 480
}
```

**验证规则：**
- 必填字段：title, type, teamId, minParticipants, maxParticipants
- minParticipants ≥ 2 且 ≤ 500
- maxParticipants ≥ minParticipants
- budgetMax ≥ budgetMin
- scheduledDate 必须是未来日期

**响应示例：**
```json
{
  "success": true,
  "data": {
    "activity": {
      "id": "act_1234567890",
      "title": "户外团建烧烤",
      "description": "组织团队户外烧烤活动，增进团队感情",
      "type": "OUTDOOR",
      "status": "DRAFT",
      "teamId": "team_1234567890",
      "creatorId": "usr_1234567890",
      "minParticipants": 10,
      "maxParticipants": 30,
      "budgetMin": 2000,
      "budgetMax": 5000,
      "budgetCurrency": "CNY",
      "location": "深圳大梅沙海滨公园",
      "scheduledDate": "2024-02-15",
      "startTime": "10:00",
      "durationMinutes": 480,
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  }
}
```

### 2. 获取活动列表
**GET** `/api/v1/activities?teamId=team_1234567890&status=DRAFT&page=1&size=20`

**响应示例：**
```json
{
  "success": true,
  "data": {
    "activities": [
      {
        "id": "act_1234567890",
        "title": "户外团建烧烤",
        "type": "OUTDOOR",
        "status": "DRAFT",
        "minParticipants": 10,
        "maxParticipants": 30,
        "budgetMin": 2000,
        "budgetMax": 5000,
        "participantCount": 15,
        "scheduledDate": "2024-02-15",
        "createdAt": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "size": 20,
      "total": 5,
      "pages": 1
    }
  }
}
```

### 3. 获取活动详情
**GET** `/api/v1/activities/{activityId}`

**响应示例：**
```json
{
  "success": true,
  "data": {
    "activity": {
      "id": "act_1234567890",
      "title": "户外团建烧烤",
      "description": "组织团队户外烧烤活动，增进团队感情",
      "type": "OUTDOOR",
      "status": "DRAFT",
      "team": {
        "id": "team_1234567890",
        "name": "产品研发部"
      },
      "creator": {
        "id": "usr_1234567890",
        "fullName": "张三",
        "email": "alice@company.com"
      },
      "minParticipants": 10,
      "maxParticipants": 30,
      "budgetMin": 2000,
      "budgetMax": 5000,
      "budgetCurrency": "CNY",
      "location": "深圳大梅沙海滨公园",
      "scheduledDate": "2024-02-15",
      "startTime": "10:00",
      "durationMinutes": 480,
      "participants": {
        "confirmed": 15,
        "pending": 5,
        "total": 20
      },
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  }
}
```

### 4. 更新活动
**PUT** `/api/v1/activities/{activityId}`

**请求参数：**
```json
{
  "title": "户外团建烧烤+游戏",
  "description": "更新后的活动描述",
  "minParticipants": 15,
  "maxParticipants": 35,
  "budgetMin": 2500,
  "budgetMax": 6000
}
```

### 5. 删除活动
**DELETE** `/api/v1/activities/{activityId}`

### 6. 更新活动状态
**PATCH** `/api/v1/activities/{activityId}/status`

**请求参数：**
```json
{
  "status": "IN_PROGRESS"
}
```

状态流转：DRAFT → IN_PROGRESS → COMPLETED/CANCELLED

### 7. 添加活动参与者
**POST** `/api/v1/activities/{activityId}/participants`

**请求参数：**
```json
{
  "userId": "usr Bobby1234567",
  "role": "PARTICIPANT"
}
```

### 8. 获取活动参与者列表
**GET** `/api/v1/activities/{activityId}/participants`

**响应示例：**
```json
{
  "success": true,
  "data": {
    "participants": [
      {
        "id": "part_1234567890",
        "user": {
          "id": "usr_1234567890",
          "fullName": "张三",
          "email": "alice@company.com"
        },
        "status": "CONFIRMED",
        "joinedAt": "2024-01-15T10:30:00Z"
      }
    ],
    "summary": {
      "total": 20,
      "confirmed": 15,
      "pending": 3,
      "declined": 2
    }
  }
}
```

## AI推荐 API

### 1. 获取活动推荐
**POST** `/api/v1/ai/recommendations`

**请求参数：**
```json
{
  "teamId": "team_1234567890",
  "participants": 20,
  "budgetMin": 2000,
  "budgetMax": 5000,
  "preferences": ["OUTDOOR", "TEAM_BUILDING"],
  "duration": "HALF_DAY",
  "location": "深圳",
  "preferredDates": ["2024-02-15", "2024-02-20", "2024-02-25"]
}
```

**验证规则：**
- 参与人数：2-500人
- 预算限制：budgetMin ≤ budgetMax
- 偏好类型：从预设枚举中选择

**响应示例：**
```json
{
  "success": true,
  "data": {
    "recommendations": [
      {
        "id": "rec_1234567890",
        "title": "团队户外拓展训练",
        "description": "通过攀岩、定向等户外活动提升团队协作能力",
        "type": "OUTDOOR",
        "estimatedCost": {
          "min": 2500,
          "max": 3500,
          "currency": "CNY"
        },
        "duration": 360,
        "suitableFor": {
          "minParticipants": 15,
          "maxParticipants": 30
        },
        "location": "梧桐山拓展训练基地",
        "difficulty": "MEDIUM",
        "equipmentNeeded": ["运动鞋", "运动服", "防晒霜"],
        "weatherDependant": true,
        "rating": 4.5,
        "reviewCount": 128
      },
      {
        "id": "rec_1234567891",
        "title": "真人密室逃脱",
        "description": "分组进行密室逃脱挑战，锻炼逻辑思维",
        "type": "INDOOR",
        "estimatedCost": {
          "min": 1800,
          "max": 2400,
          "currency": "CNY"
        },
        "duration": 120,
        "suitableFor": {
          "minParticipants": 10,
          "maxParticipants": 25
        },
        "location": "市中心真人密室逃脱馆",
        "difficulty": "EASY",
        "equipmentNeeded": [],
        "weatherDependant": false,
        "rating": 4.3,
        "reviewCount": 89
      },
      {
        "id": "rec_1234567892",
        "title": "自助烧烤+团队游戏",
        "description": "户外烧烤结合趣味团队游戏，轻松愉快",
        "type": "OUTDOOR",
        "estimatedCost": {
          "min": 2200,
          "max": 2800,
          "currency": "CNY"
        },
        "duration": 240,
        "suitableFor": {
          "minParticipants": 10,
          "maxParticipants": 30
        },
        "location": "大梅沙海滨公园",
        "difficulty": "EASY",
        "equipmentNeeded": ["防晒用品"],
        "weatherDependant": true,
        "rating": 4.2,
        "reviewCount": 156
      }
    ],
    "recommendationId": "req_1234567890",
    "generatedAt": "2024-01-15T10:30:00Z",
    "cacheHit": false,
    "processingTimeMs": 2480
  }
}
```

### 2. 提交推荐反馈
**POST** `/api/v1/ai/recommendations/{recommendationId}/feedback`

**请求参数：**
```json
{
  "feedback": "LIKE",
  "reason": "选择了真人密室逃脱"
}
```

## 时间协调 API

### 1. 获取活动可用时间
**GET** `/api/v1/activities/{activityId}/available-times`

**响应示例：**
```json
{
  "success": true,
  "data": {
    "proposedTimes": [
      {
        "date": "2024-02-15",
        "startTime": "09:00",
        "endTime": "17:00",
        "totalVotes": 18,
        "positiveVotes": 15,
        "negativeVotes": 3,
        "suitability": "OPTIMAL",
        "expectedParticipants": 20
      },
      {
        "date": "2024-02-20",
        "startTime": "09:00",
        "endTime": "17:00",
        "totalVotes": 12,
        "positiveVotes": 8,
        "negativeVotes": 4,
        "suitability": "GOOD",
        "expectedParticipants": 18
      },
      {
        "date": "2024-02-25",
        "startTime": "09:00",
        "endTime": "17:00",
        "totalVotes": 10,
        "positiveVotes": 5,
        "negativeVotes": 5,
        "suitability": "FAIR",
        "expectedParticipants": 15
      }
    ],
    "participationRate": 80.0,
    "totalInvited": 25,
    "hasResponded": 20,
    "bestTime": {
      "date": "2024-02-15",
      "startTime": "09:00",
      "endTime": "17:00"
    }
  }
}
```

### 2. 提交时间偏好
**POST** `/api/v1/activities/{activityId}/time-preferences`

**请求参数：**
```json
{
  "preferences": [
    {
      "date": "2024-02-15",
      "startTime": "09:00",
      "endTime": "17:00",
      "availabilityLevel": 5,
      "notes": "我的首选时间"
    },
    {
      "date": "2024-02-20",
      "startTime": "09:00",
      "endTime": "17:00",
      "availabilityLevel": 3,
      "notes": "如果有冲突可调整"
    }
  ]
}
```

### 3. 投票选择时间
**POST** `/api/v1/activities/{activityId}/time-votes`

**请求参数：**
```json
{
  "proposedTimeId": "ptime_1234567890",
  "vote": "POSITIVE"
}
```

## 错误代码表

| 错误代码 | 描述 | HTTP状态码 |
|---------|------|------------|
| SUCCESS | 操作成功 | 200 |
| PARAM_INVALID | 参数无效 | 400 |
| AUTH_INVALID_TOKEN | 无效的访问令牌 | 401 |
| AUTH_TOKEN_EXPIRED | 访问令牌已过期 | 401 |
| AUTH_INVALID_CREDENTIALS | 无效的登录凭据 | 401 |
| AUTH_PERMISSION_DENIED | 权限不足 | 403 |
| RESOURCE_NOT_FOUND | 请求的资源不存在 | 404 |
| RESOURCE_ALREADY_EXISTS | 资源已存在 | 409 |
| BUSINESS_LOGIC_ERROR | 业务逻辑错误 | 422 |
| SERVER_INTERNAL_ERROR | 服务器内部错误 | 500 |
| SERVICE_UNAVAILABLE | 服务暂不可用 | 503 |

## 分页参数

所有列表接口都支持分页：

| 参数 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| page | integer | 1 | 页码，从1开始 |
| size | integer | 20 | 每页条数，最大100 |
| sort | string | -createdAt | 排序字段，加-表示降序 |

## 限流规则

### 基础限流
- 未认证请求：60次/分钟/IP
- 认证请求：600次/分钟/用户

### 特殊限流
- 登录/注册：10次/小时/IP
- AI推荐生成：20次/小时/用户
- 批量操作：10次/分钟/用户

## WebHook通知

支持以下事件通知：

### 事件类型
- `activity.created` - 活动创建
- `activity.updated` - 活动更新
- `activity.status_changed` - 活动状态变更
- `team.member_added` - 团队成员添加
- `team.member_removed` - 团队成员移除

### 载荷格式
```json
{
  "eventType": "activity.created",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "activityId": "act_1234567890",
    "creatorId": "usr_1234567890",
    "teamId": "team_1234567890"
  },
  "signature": "sha256=..."
}
```

## SDK和工具

### Postman集合
提供完整的Postman测试集合文件：`TeamBuildingAPI.postman_collection.json`

### 代码生成
支持OpenAPI Generator自动生成客户端代码：
```bash
openapi-generator generate \
  -i https://api.team-building.com/api-docs.json \
  -g typescript-axios \
  -o ./api-client
```

### 错误处理示例
```javascript
// 前端错误处理示例
try {
  const response = await api.createActivity(activityData);
  message.success('活动创建成功');
} catch (error) {
  if (error.response?.data?.error?.code === 'PARAM_INVALID') {
    form.setFields(error.response.data.error.details);
  } else {
    message.error('创建失败，请稍后重试');
  }
}
```

## API版本策略

采用URL路径版本控制：
- v1: 当前版本
- v2: 下一个主要版本（预计6个月后）

向后兼容保证：
- 现有接口在6个月内不会移除
- 新增字段默认为向后兼容
- 重大变更将通过v2版本发布

---

**API规范制定完成** ✅
**基于MVP功能需求的RESTful设计** 🎯
**支持前端集成和后端实现** 🔧

本API规范完全对应MVP的73个测试用例要求，为开发团队提供明确的接口标准！
