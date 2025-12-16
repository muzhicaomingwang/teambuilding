# 前端设计方案 - 团建助手 (Frontend Design - Team Building Assistant)

**前端工程师输出文档**

## 1. 技术架构概述 (Technical Architecture Overview)

### 1.1 前端整体架构图
```
User Interface Layer
├── Mobile Web App
├── Progressive Web App
└── Desktop Web Application

Business Logic Layer
├── React Components
├── Redux Store (State Management)
├── Redux Toolkit RTK Query (API Layer)
└── Custom Hooks (Business Logic)

Data Access Layer
├── RESTful API Service
├── GraphQL Service
├── WebSocket Service
└── Local Storage

Infrastructure Layer
├── Build Tools (Vite)
├── Testing Framework
├── Code Quality Tools
└── CI/CD Pipeline
```

### 1.2 技术选型理由

#### 1.2.1 框架选择 - React 18
```javascript
选择理由:
{
  "优势": {
    "组件化": "模块化开发，复用性高",
    "生态丰富": "海量组件和工具支持",
    "性能优化": "新版本包含并发特性、Suspense等",
    "团队熟悉度": "主流技术栈，人才储备充足",
    "企业支持": "Meta维护，长期稳定"
  },
  "适用性": {
    "企业级应用": "复杂状态管理支持",
    "多终端适配": "PWA技术支持",
    "SEO需求": "SSR支持（Next.js选项）",
    "国际化": "成熟解决方案"
  }
}
```

#### 1.2.2 状态管理 - Redux Toolkit
```javascript
// Redux Toolkit配置示例
import { configureStore } from '@reduxjs/toolkit'
import activitySlice from './slices/activitySlice'
import teamSlice from './slices/teamSlice'
import userSlice from './slices/userSlice'

export const store = configureStore({
  reducer: {
    activity: activitySlice,
    team: teamSlice,
    user: userSlice
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: ['persist/PERSIST']
      }
    })
})
```

## 2. 组件架构设计 (Component Architecture)

### 2.1 组件层级结构
```
src/
├── components/           # 通用组件
│   ├── ui/              # 基础UI组件
│   │   ├── Button/
│   │   ├── Card/
│   │   ├── Form/
│   │   └── Modal/
│   ├── business/        # 业务组件
│   │   ├── ActivityCard/
│   │   ├── TeamMemberList/
│   │   └── BudgetProgress/
│   └── layout/          # 布局组件
│       ├── Header/
│       ├── Sidebar/
│       └── Content/
├── pages/               # 页面组件
│   ├── Dashboard/
│   ├── Activity/
│   ├── Team/
│   └── Analytics/
├── containers/          # 容器组件
│   ├── ActivityListContainer/
│   └── TeamManagementContainer/
└── hooks/               # 自定义Hooks
    ├── useActivity.ts
    ├── useTeam.ts
    └── useAuth.ts
```

### 2.2 组件设计模式

#### 2.2.1 原子化设计 (Atomic Design)
```javascript
原子组件 (Atoms):
├── Button - 基础按钮
├── Input - 输入框
├── Label - 标签
└── Icon - 图标

分子组件 (Molecules):
├── SearchBar - 搜索栏
├── FormField - 表单字段
├── UserCard - 用户卡片
└── ActivityTag - 活动标签

有机体组件 (Organisms):
├── ActivityForm - 活动表单
├── TeamList - 团队列表
├── BudgetPanel - 预算面板
└── CommentSection - 评论区

模板 (Templates):
├── DashboardLayout - 仪表板布局
├── ActivityLayout - 活动页布局
└── SettingsLayout - 设置页布局

页面 (Pages):
├── DashboardPage - 仪表板页面
├── ActivityPage - 活动详情页
└── SettingsPage - 设置页面
```

#### 2.2.2 复合组件示例
```jsx
// ActivityCard复合组件
import React from 'react';
import { Card, Button, Avatar, Progress, Tag } from 'antd';
import { EnvironmentOutlined, ClockCircleOutlined, TeamOutlined } from '@ant-design/icons';

interface ActivityCardProps {
  activity: Activity;
  onEdit: (id: string) => void;
  onDelete: (id: string) => void;
  onShare: (id: string) => void;
}

const ActivityCard: React.FC<ActivityCardProps> = ({ activity, onEdit, onDelete, onShare }) => {
  const {
    id,
    title,
    location,
    date,
    time,
    participants,
    budget,
    status,
    image
  } = activity;

  return (
    <Card
      hoverable
      cover={<img alt={title} src={image} />}
      actions={[
        <Button type="link" onClick={() => onEdit(id)}>编辑</Button>,
        <Button type="link" onClick={() => onShare(id)}>分享</Button>,
        <Button type="link" danger onClick={() => onDelete(id)}>删除</Button>
      ]}
    >
      <Card.Meta
        title={
          <div className="activity-card-title">
            {title}
            <Tag color={getStatusColor(status)}>{status}</Tag>
          </div>
        }
        description={
          <div className="activity-card-description">
            <div className="activity-info">
              <p><EnvironmentOutlined /> {location}</p>
              <p><ClockCircleOutlined /> {date} {time}</p>
              <p><TeamOutlined /> {participants?.length || 0}人参与</p>
            </div>
            <div className="activity-progress">
              <span>预算: ¥{budget.used} / ¥{budget.total}</span>
              <Progress
                percent={(budget.used / budget.total) * 100}
                strokeColor={getBudgetColor(budget.used, budget.total)}
                showInfo={false}
              />
            </div>
          </div>
        }
      />
    </Card>
  );
};

export default ActivityCard;
```

## 3. 状态管理设计 (State Management Design)

### 3.1 Redux State Architecture
```javascript
// 根状态结构
interface RootState {
  auth: {
    isAuthenticated: boolean;
    user: User | null;
    permissions: string[];
  };

  activity: {
    activities: Activity[];
    currentActivity: Activity | null;
    selectedActivities: string[];
    filters: ActivityFilters;
    pagination: PaginationState;
    loading: boolean;
    error: string | null;
  };

  team: {
    teams: Team[];
    currentTeam: Team | null;
    members: Member[];
    selectedMembers: string[];
    loading: boolean;
  };

  dashboard: {
    stats: DashboardStats;
    recentActivities: Activity[];
    upcomingActivities: Activity[];
    loading: boolean;
  };

  ui: {
    theme: 'light' | 'dark' | 'auto';
    sidebarCollapsed: boolean;
    notifications: Notification[];
    modals: ModalState[];
  };
}
```

### 3.2 RTK Query API Layer
```javascript
// API服务定义
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

export const activityApi = createApi({
  reducerPath: 'activityApi',
  baseQuery: fetchBaseQuery({
    baseUrl: process.env.REACT_APP_API_URL,
    prepareHeaders: (headers, { getState }) => {
      const token = (getState() as RootState).auth.token;
      if (token) {
        headers.set('authorization', `Bearer ${token}`);
      }
      return headers;
    },
  }),
  tagTypes: ['Activity', 'Team', 'Member'],
  endpoints: (builder) => ({
    // 活动相关API
    getActivities: builder.query<ActivitiesResponse, GetActivitiesParams>({
      query: (params) => ({
        url: 'activities',
        params,
      }),
      providesTags: ['Activity'],
    }),

    createActivity: builder.mutation<Activity, CreateActivityRequest>({
      query: (body) => ({
        url: 'activities',
        method: 'POST',
        body,
      }),
      invalidatesTags: ['Activity'],
      async onQueryStarted(args, { dispatch, queryFulfilled }) {
        try {
          const { data } = await queryFulfilled;
          dispatch(showNotification({
            type: 'success',
            message: '活动创建成功',
            description: data.title
          }));
        } catch (error) {
          dispatch(showNotification({
            type: 'error',
            message: '创建失败',
            description: error.message
          }));
        }
      }
    }),

    // 通过智能推荐创建活动
    createActivityWithAI: builder.mutation<AICreatedActivity, CreateActivityAIRequest>({
      query: (body) => ({
        url: 'activities/ai/create',
        method: 'POST',
        body: JSON.stringify(body),
        headers: {
          'Content-Type': 'application/json',
        },
      }),
      transformResponse: (response: AIResponse) => {
        // 解析AI响应并进行数据转换
        return {
          activities: response.recommendations.map(rec => ({
            ...rec,
            aiScore: rec.confidence,
            estimatedCost: rec.budgetBreakdown?.total
          }))
        };
      }
    }),
  }),
});

export const {
  useGetActivitiesQuery,
  useCreateActivityMutation,
  useCreateActivityWithAIMutation,
} = activityApi;
```

### 3.3 状态持久化 (State Persistence)
```javascript
// 持久化配置
import { persistStore, persistReducer } from 'redux-persist';
import storage from 'redux-persist/lib/storage';

const persistConfig = {
  key: 'root',
  storage,
  whitelist: ['auth', 'ui', 'dashboard.prefs', 'activity.filters'],
  blacklist: ['activity.loading', 'ui.modals', 'api']
};

const persistedReducer = persistReducer(persistConfig, rootReducer);
export const persistor = persistStore(store);
```

## 4. 路由设计 (Routing Design)

### 4.1 路由结构
```javascript
// 路由配置
import { createBrowserRouter } from 'react-router-dom';

const router = createBrowserRouter([
  {
    path: '/',
    element: <AppLayout />,
    errorElement: <ErrorBoundary />,
    children: [
      {
        index: true,
        element: <Navigate to="/dashboard" replace />
      },
      {
        path: 'dashboard',
        element: <DashboardPage />,
        loader: dashboardLoader,
      },
      {
        path: 'activities',
        children: [
          {
            index: true,
            element: <ActivityListPage />,
            loader: activitiesListLoader,
          },
          {
            path: 'new',
            element: <CreateActivityWizard />,
            children: [
              {
                path: 'step1',
                element: <BasicInfoStep />
              },
              {
                path: 'step2',
                element: <AIRecommendationsStep />
              },
              {
                path: 'step3',
                element: <PlanDetailsStep />
              }
            ]
          },
          {
            path: ':activityId',
            element: <ActivityDetailsLayout />,
            loader: activityDetailsLoader,
            children: [
              {
                index: true,
                element: <Navigate to="overview" replace />
              },
              {
                path: 'overview',
                element: <ActivityOverviewTab />
              },
              {
                path: 'members',
                element: <ActivityMembersTab />
              },
              {
                path: 'budget',
                element: <ActivityBudgetTab />
              },
              {
                path: 'schedule',
                element: <ActivityScheduleTab />
              },
              {
                path: 'feedback',
                element: <ActivityFeedbackTab />
              },
              {
                path: 'gallery',
                element: <ActivityGalleryTab />
              }
            ]
          }
        ]
      },
      {
        path: 'teams',
        element: <TeamManagementPage />,
        children: [
          {
            index: true,
            element: <TeamList />
          },
          {
            path: ':teamId',
            element: <TeamDetailsPage />,
            children: [
              {
                path: 'members',
                element: <TeamMembersTab />
              },
              {
                path: 'activities',
                element: <TeamActivitiesTab />
              },
              {
                path: 'analytics',
                element: <TeamAnalyticsTab />
              }
            ]
          }
        ]
      },
      {
        path: 'analytics',
        element: <AnalyticsPage />,
        children: [
          {
            index: true,
            element: <Navigate to="overview" replace />
          },
          {
            path: 'overview',
            element: <AnalyticsOverview />
          },
          {
            path: 'trends',
            element: <AnalyticsTrends />
          },
          {
            path: 'reports',
            element: <AnalyticsReports />
          }
        ]
      },
      {
        path: 'settings',
        element: <SettingsPage />,
        children: [
          { path: 'profile', element: <ProfileSettings /> },
          { path: 'notifications', element: <NotificationSettings /> },
          { path: 'privacy', element: <PrivacySettings /> },
          { path: 'help', element: <HelpAndSupport /> }
        ]
      }
    ],
  },
  {
    path: '/auth',
    element: <AuthLayout />,
    children: [
      { path: 'login', element: <LoginPage /> },
      { path: 'register', element: <RegisterPage /> },
      { path: 'forgot-password', element: <ForgotPasswordPage /> }
    ]
  }
]);
```

### 4.2 路由守卫 (Route Guards)
```javascript
// 认证守卫示例
import { Navigate, useLocation } from 'react-router-dom';

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated } = useAppSelector(state => state.auth);
  const location = useLocation();

  if (!isAuthenticated) {
    return <Navigate to="/auth/login" state={{ from: location }} replace />;
  }

  return children;
};

// 权限守卫示例
const PermissionGuard = ({ children, requiredPermission }) => {
  const { user } = useAppSelector(state => state.auth);
  const hasPermission = user?.permissions?.includes(requiredPermission);

  if (!hasPermission) {
    return <Navigate to="/403" replace />;
  }

  return children;
};
```

### 4.3 数据预加载 (Data Preloading)
```javascript
// Loader函数示例
export const activityDetailsLoader = async ({ params }) => {
  try {
    const activityId = params.activityId;

    // 预加载活动详情数据
    const activity = await activityApi.getActivityById(activityId);
    const members = await teamApi.getActivityMembers(activityId);
    const feedback = await activityApi.getActivityFeedback(activityId);

    return {
      activity,
      members,
      feedback,
      notFound: false
    };
  } catch (error) {
    if (error.status === 404) {
      return { notFound: true };
    }
    throw error;
  }
};
```

## 5. 性能优化策略 (Performance Optimization)

### 5.1 代码分割和懒加载
```javascript
// 路由级别的懒加载
import { lazy, Suspense } from 'react';

const ActivityList = lazy(() => import('./pages/ActivityList'));
const Settings = lazy(() => import('./pages/Settings'));
const Analytics = lazy(() => import('./pages/Analytics'));

// 组件级别的懒加载
const HeavyChart = lazy(() => import('./components/HeavyChart'));
const RichTextEditor = lazy(() => import('./components/RichTextEditor'));

// 使用示例
function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/activities" element={<ActivityList />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/analytics" element={<Analytics />} />
      </Routes>
    </Suspense>
  );
}
```

### 5.2 虚拟列表优化
```javascript
// 大数据量列表组件
import { FixedSizeList, VariableSizeList } from 'react-window';

const ActivityList: React.FC<Props> = ({ activities }) => {
  const itemHeight = 120;

  const Row = ({ index, style }) => (
    <div style={style}>
      <ActivityCard activity={activities[index]} />
    </div>
  );

  return (
    <FixedSizeList
      height={800}
      itemCount={activities.length}
      itemSize={itemHeight}
      width="100%"
    >
      {Row}
    </FixedSizeList>
  );
};
```

### 5.3 图片优化
```javascript
// 图片懒加载组件
import { LazyLoadImage } from 'react-lazy-load-image-component';

const OptimizedActivityImage: React.FC<Props> = ({ src, alt }) => {
  return (
    <LazyLoadImage
      src={src}
      alt={alt}
      effect="blur"
      placeholderSrc="/images/activity-placeholder.svg"
      threshold={100}
      visibleByDefault={false}
      afterLoad={() => console.log('Image loaded')}
    />
  );
};

// 响应式图片
<picture>
  <source media="(max-width: 768px)" srcSet="activity-mobile.webp" />
  <source media="(max-width: 1024px)" srcSet="activity-tablet.webp" />
  <source srcSet="activity-desktop.webp" />
  <img src="activity.jpg" alt="Activity" loading="lazy" />
</picture>
```

### 5.4 缓存策略
```javascript
// Service Worker缓存配置
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open('team-building-v1').then(cache => {
      return cache.addAll([
        '/',
        '/static/js/bundle.js',
        '/static/css/main.css',
        '/images/activity-placeholder.svg'
      ]);
    })
  );
});

// React Query缓存配置
import { QueryClient } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5分钟
      cacheTime: 1000 * 60 * 10, // 10分钟
      refetchOnWindowFocus: false,
      retry: 3,
      retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, 30000),
    },
  },
});
```

### 5.5 防抖节流应用
```javascript
// 搜索防抖
const useDebounce = (value, delay) => {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => clearTimeout(handler);
  }, [value, delay]);

  return debouncedValue;
};

// 使用示例
const SearchBar: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const debouncedSearchTerm = useDebounce(searchTerm, 300);

  useEffect(() => {
    if (debouncedSearchTerm) {
      dispatch(searchActivities(debouncedSearchTerm));
    }
  }, [debouncedSearchTerm, dispatch]);

  return (
    <Input
      placeholder="搜索活动..."
      value={searchTerm}
      onChange={(e) => setSearchTerm(e.target.value)}
      suffix={<SearchOutlined />}
    />
  );
};
```

## 6. 表单设计与验证 (Form Design and Validation)

### 6.1 表单状态管理
```javascript
// 复杂表单状态管理
import { useForm, Controller } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';

const activitySchema = yup.object({
  title: yup.string().required('请输入活动标题').max(100, '标题过长'),
  type: yup.string().required('请选择活动类型'),
  participants: yup.number().integer().positive().min(2, '至少2人参与'),
  budget: yup.object({
    min: yup.number().min(100, '预算过低'),
    max: yup.number().moreThan(yup.ref('min'), '上限应大于下限')
  }),
  date: yup.date().min(new Date(), '应选择将来的日期'),
  location: yup.string().required('请输入活动地点'),
  description: yup.string()
});

const ActivityForm: React.FC = () => {
  const {
    control,
    handleSubmit,
    formState: { errors, isSubmitting }
  } = useForm({
    resolver: yupResolver(activitySchema),
    defaultValues: {
      title: '',
      type: 'OUTDOOR',
      participants: 20,
      budget: { min: 5000, max: 20000 },
      date: dayjs().add(7, 'day').format('YYYY-MM-DD'),
      location: '',
      description: ''
    }
  });

  const onSubmit = async (data) => {
    try {
      await dispatch(createActivity(data));
      message.success('活动创建成功');
    } catch (error) {
      message.error(error.message);
    }
  };

  return (
    <Form onFinish={handleSubmit(onSubmit)}>
      <Form.Item label="活动标题" validateStatus={errors.title ? 'error' : ''} help={errors.title?.message}>
        <Controller
          name="title"
          control={control}
          render={({ field }) => <Input {...field} placeholder="请输入活动标题" />}
        />
      </Form.Item>
    </Form>
  );
};
```

### 6.2 分步表单设计
```javascript
// 多步骤创建活动表单
import { Steps } from 'antd';

const steps = [
  {
    title: '基本信息',
    content: BasicInfoStep,
    icon: <UserOutlined />
  },
  {
    title: 'AI推荐',
    content: AIRecommendationsStep,
    icon: <RobotOutlined />
  },
  {
    title: '详细规划',
    content: PlanDetailsStep,
    icon: <ScheduleOutlined />
  },
  {
    title: '确认发布',
    content: ConfirmPublishStep,
    icon: <CheckCircleOutlined />
  }
];

const CreateActivityWizard: React.FC = () => {
  const [current, setCurrent] = useState(0);
  const [formData, setFormData] = useState({});

  const handleNext = (stepData) => {
    setFormData({ ...formData, ...stepData });
    setCurrent(current + 1);
  };

  const handlePrevious = () => {
    setCurrent(current - 1);
  };

  const CurrentStep = steps[current].content;

  return (
    <div className="activity-creation-wizard">
      <Steps current={current} items={steps} />
      <div className="step-content">
        <CurrentStep formData={formData} onNext={handleNext} />
      </div>
      <div className="step-actions">
        {current > 0 && (
          <Button onClick={handlePrevious}>上一步</Button>
        )}
        {current < steps.length - 1 && (
          <Button type="primary" onClick={onFinish}>下一步</Button>
        )}
        {current === steps.length - 1 && (
          <Button type="primary" onClick={onSubmit}>创建活动</Button>
        )}
      </div>
    </div>
  );
};
```

## 7. 实时通信实现 (Real-time Communication)

### 7.1 WebSocket连接管理
```javascript
// WebSocket Hook
import { useState, useEffect, useRef } from 'react';
import { io, Socket } from 'socket.io-client';

const useWebSocket = (url: string, userId: string) => {
  const socketRef = useRef<Socket>();
  const [connected, setConnected] = useState(false);
  const [activities, setActivities] = useState<Activity[]>([]);

  useEffect(() => {
    const socket = io(url, {
      auth: { userId },
      transports: ['websocket'],
      upgrade: false,
    });

    socketRef.current = socket;

    socket.on('connect', () => {
      setConnected(true);
      console.log('WebSocket connected');
    });

    socket.on('disconnect', () => {
      setConnected(false);
      console.log('WebSocket disconnected');
    });

    socket.on('activity:created', (data) => {
      setActivities(prev => [...prev, data]);
    });

    socket.on('activity:updated', (data) => {
      setActivities(prev =>
        prev.map(activity =>
          activity.id === data.id ? data : activity
        )
      );
    });

    socket.on('activity:status-changed', ({ activityId, status }) => {
      setActivities(prev =>
        prev.map(activity =>
          activity.id === activityId
            ? { ...activity, status }
            : activity
        )
      );
    });

    return () => {
      socket.disconnect();
    };
  }, [url, userId]);

  const sendMessage = (event: string, data: any) => {
    if (socketRef.current?.connected) {
      socketRef.current.emit(event, data);
    }
  };

  return {
    socket: socketRef.current,
    connected,
    activities,
    sendMessage
  };
};
```

### 7.2 协同时钟同步
```javascript
// 时间协调组件中的实时更新
const TimeCoordination: React.FC = ({ activityId }) => {
  const { connected, sendMessage, activities } = useWebSocket(WS_URL, currentUser.id);
  const [availabilities, setAvailabilities] = useState({});

  const handleAvailabilityUpdate = (date: string, timeSlot: string) => {
    const data = {
      activityId,
      userId: currentUser.id,
      date,
      timeSlot,
      timestamp: new Date().toISOString()
    };

    sendMessage('availability:update', data);
  };

  useEffect(() => {
    if (connected) {
      sendMessage('availability:subscribe', { activityId });
    }
  }, [connected, activityId, sendMessage]);

  return (
    <div className="time-coordination">
      <AvailabilityCalendar
        availabilities={availabilities}
        onSelect={handleAvailabilityUpdate}
        readOnly={!connected || activity.status !== 'PLANNING'}
      />
      {!connected && <Alert message="实时协作已断开连接" type="warning" />}
    </div>
  );
};
```

## 8. 错误处理与恢复 (Error Handling and Recovery)

### 8.1 错误边界组件 (Error Boundary)
```javascript
// 错误边界组件
import React, { Component, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: React.ErrorInfo | null;
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null
    };
  }

  static getDerivedStateFromError(error: Error): State {
    return {
      hasError: true,
      error,
      errorInfo: null
    };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    // 发送错误到监控服务
    console.error('Capture error:', error, errorInfo);

    this.setState({
      error,
      errorInfo
    });

    // 上报错误到监控服务
    reportError(error, errorInfo);
  }

  handleReset = () => {
    this.setState({
      hasError: false,
      error: null,
      errorInfo: null
    });
  };

  handleRetry = () => {
    window.location.reload();
  };

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }

      return (
        <div className="error-boundary-fallback">
          <div className="error-boundary-content">
            <h2>😅 出现故障</h2>
            <p>异常信息已记录，我们正在处理中...</p>
            <div className="error-boundary-actions">
              <Button onClick={this.handleReset}>
                重新加载
              </Button>
              <Button type="dashed" onClick={this.handleRetry}>
                刷新页面
              </Button>
            </div>
            {process.env.NODE_ENV === 'development' && (
              <details className="error-details">
                <summary>错误详情</summary>
                <pre>{this.state.error?.stack}</pre>
              </details>
            )}
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
```

### 8.2 API错误处理
```javascript
// 全局错误处理
const handleApiError = (error: any): AppError => {
  if (error.response?.data) {
    const { status, data } = error.response;

    switch (status) {
      case 400:
        return {
          type: 'VALIDATION_ERROR',
          message: '请求参数错误',
          details: data.errors
        };
      case 401:
        return {
          type: 'AUTHENTICATION_ERROR',
          message: '登录已过期，请重新登录',
          code: 'TOKEN_EXPIRED'
        };
      case 403:
        return {
          type: 'AUTHORIZATION_ERROR',
          message: '您没有权限执行此操作',
          code: 'INSUFFICIENT_PERMISSIONS'
        };
      case 404:
        return {
          type: 'NOT_FOUND',
          message: '请求的资源不存在',
          resource: data.resource
        };
      case 409:
        return {
          type: 'CONFLICT',
          message: '操作冲突',
          conflict: data.conflict
        };
      case 500:
        return {
          type: 'SERVER_ERROR',
          message: '服务器内部错误",
          requestId: data.requestId
        };
      default:
        return {
          type: 'UNKNOWN_ERROR',
          message: '发生未知错误',
          error
        };
    }
  }

  // 网络错误
  if (error.code === 'ECONNREFUSED') {
    return {
      type: 'NETWORK_ERROR',
      message: '网络连接失败',
      retryable: true
    };
  }

  // 超时错误
  if (error.code === 'ETIMEDOUT') {
    return {
      type: 'TIMEOUT_ERROR',
      message: '请求超时',
      retryable: true
    };
  }

  return {
    type: 'UNKNOWN_ERROR',
    message: error.message || '发生未知错误'
  };
};
```

### 8.3 统一错误展示
```javascript
// 错误展示组件
import { Alert, Button, Space } from 'antd';

interface ErrorDisplayProps {
  error: AppError;
  onRetry?: () => void;
  onFallback?: () => void;
}

const ErrorDisplay: React.FC<ErrorDisplayProps> = ({ error, onRetry, onFallback }) => {
  const [showDetails, setShowDetails] = useState(false);

  const getAlertType = () => {
    switch (error.type) {
      case 'VALIDATION_ERROR':
      case 'CONFLICT':
        return 'warning';
      case 'SERVER_ERROR':
      case 'NOT_FOUND':
        return 'error';
      default:
        return 'info';
    }
  };

  const renderActionButtons = () => {
    if (error.retryable && onRetry) {
      return (
        <Button type="primary" onClick={onRetry}>
          重试
        </Button>
      );
    }

    if (onFallback) {
      return (
        <Space>
          <Button onClick={onFallback}>返回</Button>
          <Button type="primary">
            <a href="/help">获取帮助</a>
          </Button>
        </Space>
      );
    }

    return null;
  };

  return (
    <div className="error-display">
      <Alert
        type={getAlertType()}
        message={error.message}
        description={
          error.details ? (
            <div>
              <p>问题详情：</p>
              <ul>
                {Object.entries(error.details).map(([field, message]) => (
                  <li key={field}>{field}: {message}</li>
                ))}
              </ul>
            </div>
          ) : null
        }
        action={renderActionButtons()}
      />
      {process.env.NODE_ENV === 'development' && (
        <Button size="small" onClick={() => setShowDetails(!showDetails)}>
          {showDetails ? '隐藏' : '显示'}错误详情
        </Button>
      )}
      {showDetails && (
        <pre className="error-stack">
          {JSON.stringify(error, null, 2)}
        </pre>
      )}
    </div>
  );
};
```

## 9. 测试策略 (Testing Strategy)

### 9.1 测试金字塔
```
        /\
       /  \
      /Unit \
     / Tests\
    /________\
   /         \
  /Integration\
 /   Tests   \
/____________\
/            \
/E2E Tests    \
/____________\
```

### 9.2 单元测试 (Unit Tests)
```javascript
// 组件单元测试示例
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ActivityCard from '../components/ActivityCard';

const mockActivity = {
  id: '1',
  title: 'Team Building Event',
  location: 'Beijing Park',
  date: '2024-02-01',
  participants: ['user1', 'user2'],
  budget: { used: 5000, total: 10000 }
};

describe('ActivityCard Component', () => {
  it('renders activity information correctly', () => {
    render(<ActivityCard activity={mockActivity} />);

    expect(screen.getByText('Team Building Event')).toBeInTheDocument();
    expect(screen.getByText('Beijing Park')).toBeInTheDocument();
    expect(screen.getByText(/20人参与/)).toBeInTheDocument();
  });

  it('handles edit button click', async () => {
    const handleEdit = jest.fn();
    render(<ActivityCard activity={mockActivity} onEdit={handleEdit} />);

    await userEvent.click(screen.getByText('编辑'));
    expect(handleEdit).toHaveBeenCalledWith('1');
  });

  it('shows budget progress correctly', () => {
    render(<ActivityCard activity={mockActivity} />);

    const progress = screen.getByRole('progressbar');
    expect(progress).toHaveStyle('width: 50%');
  });
});
```

### 9.3 集成测试 (Integration Tests)
```javascript
// API集成测试
import { server } from '../mocks/server';
import { rest } from 'msw';
import { renderHook, waitFor } from '@testing-library/react';
import { Provider } from 'react-redux';
import { useGetActivitiesQuery } from '../services/activityApi';

describe('Activity API', () => {
  it('fetches activities successfully', async () => {
    const { result } = renderHook(() => useGetActivitiesQuery({}), {
      wrapper: ({ children }) => (
        <Provider store={store}>{children}</Provider>
      )
    });
    expect(result.current.isLoading).toBe(true);

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.isSuccess).toBe(true);
    expect(result.current.data.activities).toHaveLength(10);
  });

  it('handles API errors gracefully', async () => {
    server.use(
      rest.get('/api/activities', (req, res, ctx) => {
        return res(ctx.status(500), ctx.json({ message: 'Server error' }));
      })
    );

    const { result } = renderHook(() => useGetActivitiesQuery({}), {
      wrapper: ({ children }) => (
        <Provider store={store}>{children}</Provider>
      )
    });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });

    expect(result.current.error).toBeDefined();
  });
});
```

### 9.4 端到端测试 (E2E Tests)
```javascript
// Cypress E2E测试示例
describe('Activity Creation Flow', () => {
  beforeEach(() => {
    cy.login('test@example.com', 'password');
    cy.visit('/activities/new');
  });

  it('creates a new activity successfully', () => {
    // Step 1: Basic Info
    cy.get('[data-cy=activity-title]').type('New Team Building Event');
    cy.get('[data-cy=activity-participants]').clear().type('25');
    cy.get('[data-cy=activity-min-budget]').clear().type('5000');
    cy.get('[data-cy=activity-max-budget]').clear().type('15000');
    cy.get('[data-cy=activity-type-outdoor]').click();
    cy.get('[data-cy=next-step]').click();

    // Step 2: AI Recommendations
    cy.get('[data-cy=recommendation-item]').first().click();
    cy.get('[data-cy=use-recommendation]').click();

    // Step 3: Plan Details
    cy.get('[data-cy=activity-date]').click();
    cy.get('.ant-picker-cell-today').next().click();
    cy.get('[data-cy=activity-location]').type('Beijing Olympic Park');
    cy.get('[data-cy=submit-activity]').click();

    // Verify success
    cy.get('.ant-message-success').should('contain', '创建成功');
  });

  it('handles form validation errors', () => {
    cy.get('[data-cy=next-step]').click();

    cy.get('.ant-form-item-explain').each($error => {
      expect($error).to.contain('不能为空');
    });
  });
});
```

### 9.5 可访问性测试
```javascript
// 可访问性测试
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

describe('Accessibility', () => {
  it('activity card should be accessible', async () => {
    const { container } = render(
      <ActivityCard activity={mockActivity} />
    );

    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('modal dialogs should have proper ARIA attributes', () => {
    render(
      <Modal
        title="确认删除"
        visible={true}
        onOk={jest.fn()}
        onCancel={jest.fn()}
      />
    );

    const modal = screen.getByRole('dialog');
    expect(modal).toHaveAttribute('aria-label', '确认删除');

    const closeButton = screen.getByLabelText('Close');
    expect(closeButton).toBeInTheDocument();
  });
});
```

## 10. 性能监控与优化 (Performance Monitoring)

### 10.1 Web性能指标
```javascript
// Core Web Vitals监控
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals';

const reportWebVitals = (onPerfEntry?: (metric: any) => void) => {
  if (onPerfEntry && onPerfEntry instanceof Function) {
    getCLS(onPerfEntry);
    getFID(onPerfEntry);
    getFCP(onPerfEntry);
    getLCP(onPerfEntry);
    getTTFB(onPerfEntry);
  }
};

// 发送到分析服务
const sendToAnalytics = (metric) => {
  window.gtag('event', metric.name, {
    value: Math.round(metric.value),
    event_category: 'Web Vitals',
    event_label: metric.id,
    non_interaction: true,
  });
};

reportWebVitals(sendToAnalytics);
```

### 10.2 用户行为监控
```javascript
// React Profiler监控
import { Profiler, onRenderCallback } from 'react';

const onRender: onRenderCallback = (id, phase, actualDuration, baseDuration, startTime, commitTime) => {
  // 只监控渲染时间超过50ms的组件
  if (actualDuration > 50) {
    console.log('Slow render:', {
      id,
      phase,
      actualDuration,
      baseDuration
    });

    // 发送到监控系统
    analytics.track('React Render', {
      component: id,
      duration: actualDuration,
      phase
    });
  }
};

// 使用示例
<Profiler id="ActivityList" onRender={onRender}>
  <ActivityList activities={activities} />
</Profiler>
```

## 11. 部署与构建优化 (Build and Deployment)

### 11.1 构建配置
```javascript
// vite.config.js
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import compression from 'vite-plugin-compression';
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: [
          '@babel/plugin-proposal-optional-chaining',
          ['import', { libraryName: 'antd', libraryDirectory: 'es', style: true }]
        ],
      },
    }),
    compression({
      verbose: true,
      disable: false,
      threshold: 10240,
      algorithm: 'gzip',
      ext: '.gz'
    }),
    visualizer({
      filename: './dist/stats.html',
      open: true,
      gzipSize: true
    })
  ],
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom', 'react-router-dom'],
          'ui-vendor': ['antd', '@ant-design/icons'],
          'charts': ['recharts', 'echarts'],
          'utils': ['lodash', 'moment', 'dayjs']
        }
      }
    }
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true
      }
    }
  }
});
```

### 11.2 环境变量管理
```javascript
// .env文件
REACT_APP_API_URL=https://api.team-building.com
REACT_APP_WS_URL=wss://ws.team-building.com
REACT_APP_SENTRY_DSN=https://xxx@sentry.io/xxx

// 类型定义
declare namespace NodeJS {
  interface ProcessEnv {
    readonly NODE_ENV: 'development' | 'production' | 'test';
    readonly REACT_APP_API_URL: string;
    readonly REACT_APP_WS_URL: string;
    readonly REACT_APP_SENTRY_DSN?: string;
  }
}
```

### 11.3 部署配置
```yaml
# GitHub Actions部署配置
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'
      - name: Install dependencies
        run: npm ci
      - name: Run tests
        run: npm test -- --coverage
      - name: Upload coverage
        uses: codecov/codecov-action@v1

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v2
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'
      - name: Install dependencies
        run: npm ci
      - name: Build
        run: npm run build
        env:
          REACT_APP_API_URL: ${{ secrets.API_URL }}
          REACT_APP_WS_URL: ${{ secrets.WS_URL }}
      - name: Deploy to S3
        uses: jakejarvis/s3-sync-action@master
        with:
          args: --acl public-read --follow-symlinks --delete
        env:
          AWS_S3_BUCKET: ${{ secrets.S3_BUCKET }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

## 12. 总结与下一步 (Summary and Next Steps)

### 12.1 设计要点总结
**架构设计**: 基于React + Redux的现代化SPA架构
**组件设计**: 模块化、可复用的组件体系
**状态管理**: RTK + RTK Query集中式状态管理
**性能优化**: 代码分割、虚拟化、缓存多层次优化
**错误处理**: 完善的错误边界和恢复机制
**测试策略**: 分层测试确保代码质量
**部署方案**: 自动化CI/CD流程

### 12.2 技术栈最终确认
**核心框架**: React 18 ✅
**状态管理**: Redux Toolkit + RTK Query ✅
**路由**: React Router v6 ✅
**UI库**: Ant Design 5 ✅
**构建工具**: Vite ✅
**测试**: Jest + React Testing Library + Cypress ✅
**部署**: Docker + Kubernetes ✅

### 12.3 开发计划
**阶段一 (第1-2个月)**:
- 基础组件库搭建
- 核心页面开发
- 路由和权限系统

**阶段二 (第3-4个月)**:
- 业务功能实现
- API集成和状态管理
- 响应式适配

**阶段三 (第5-6个月)**:
- 性能优化
- 测试覆盖
- 部署和监控

### 12.4 下一步：后端实现
**后端工程师将基于**：
1. 领域分析（DDD专家输出）
2. 业务事件（业务专家输出）
3. 架构设计（架构专家输出）
4. 技术架构（技术专家输出）
5. UI/UX设计（设计师输出）
6. 前端架构（本文档输出）

**实现从Adapter层到Repository层的完整后端代码。**\n\n---\n\n**生成日期**: 2024年\n**前端工程师**: [虚拟角色输出]\n**评审状态**: 待后端工程师实现\n\n**资源链接**: \n- GitHub仓库: [待创建]\n- 设计稿: [待提供]\n- API文档: [待生成]\n- 测试环境: [待部署]