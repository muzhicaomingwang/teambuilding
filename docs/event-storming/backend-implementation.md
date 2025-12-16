# 后端实现方案 - 团建助手 (Backend Implementation - Team Building Assistant)

**后端工程师输出文档**

## 1. 整体架构 (Overall Architecture)

### 1.1 分层架构图 (Layer Architecture)
```
┌─────────────────────────────────────────────────────────────────┐
│                        Controller Layer                         │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │        REST API / GraphQL / WebSocket / gRPC               │ │
│  │   DTO → Validation → Transformation → Response Assembly    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                            │                                    │
│                            ▼                                    │ │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                 Application Service Layer                    │ │
│  │                                                             │ │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐              │ │
│  │  │   Use Case │ │    CQRS    │ │ Orchestrate │              │ │
│  │  │  Handler   │ │  Command   │ │  Service    │              │ │
│  │  │            │ │   Query    │ │             │              │ │
│  │  └─────┬──────┘ └─────┬──────┘ └─────┬───────┘              │ │
│  │        │             │             │                      │ │
│  └────────┼─────────────┼─────────────┼──────────────────────┘ │
│           │             │             │                       │
│           ▼             ▼             ▼                       │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                  Domain Layer                               │ │
│  │                                                             │ │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐              │ │
│  │  │  Aggregate │ │ Domain     │ │   Value    │              │ │
│  │  │    Root    │ │   Event    │ │   Object   │              │ │
│  │  │            │ │            │ │            │              │ │
│  │  └─────┬──────┘ └─────┬──────┘ └─────┬───────┘              │ │
│  │        │             │             │                      │ │
│  └────────┼─────────────┼─────────────┼──────────────────────┘ │
│           │             │             │                       │
│           ▼             ▼             ▼                       │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                 Infrastructure Layer                       │ │
│  │                                                             │ │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐              │ │
│  │  │   JPA     │ │  MyBatis   │ │ Database   │              │ │
│  │  │Repository │ │   Mapper   │ │ Connection │              │ │
│  │  │           │ │            │ │            │              │ │
│  │  └─────┬──────┘ └─────┬──────┘ └─────┬───────┘              │ │
│  │        │             │             │                      │ │
│  └────────┼─────────────┼─────────────┼──────────────────────┘ │
│           │             │             │                       │
│           ▼             ▼             ▼                       │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    Data Layer                               │ │
│  │           PostgreSQL     MongoDB     Redis                │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 技术栈确认 (Technology Stack Confirmation)

#### 后端主技术栈
- **语言**: Java 17 LTS
- **框架**: Spring Boot 3.2.x
- **Web**: Spring MVC + Spring WebFlux
- **数据访问**: Spring Data JPA + MyBatis
- **消息队列**: Spring Kafka + Redis Pub/Sub
- **缓存**: Redis 7.x
- **数据库**: PostgreSQL 15 (主) + MongoDB (辅)
- **搜索**: Elasticsearch 8.x
- **任务调度**: Quartz + Spring Schedule
- **安全**: Spring Security + JWT

#### 微服务技术栈
- **服务发现**: Consul
- **配置中心**: Spring Cloud Config
- **API网关**: Spring Cloud Gateway
- **断路器**: Resilience4j
- **链路追踪**: Sleuth + Zipkin
- **监控**: Prometheus + Micrometer

## 2. Adapter层实现 (Adapter Layer Implementation)

### 2.1 REST API控制器 (REST API Controllers)

#### 活动规划控制器 (Activity Planning Controller)
```java
@Slf4j
@RestController
@RequestMapping("/api/v1/activities")
@RequiredArgsConstructor
@Tag(name = "活动管理", description = "团建活动创建、查询、更新等API")
public class ActivityPlanningController {

    private final ActivityApplicationService activityAppService;
    private final ActivityDtoAssembler dtoAssembler;

    @PostMapping
    @Operation(summary = "创建团建活动", description = "根据提供的信息创建新的团建活动")
    @PreAuthorize("hasRole('TEAM_LEAD')")
    public ResponseEntity<ApiResponse<ActivityDto>> createActivity(@Valid @RequestBody CreateActivityRequest request) {
        log.info("创建新活动请求: {}", request);

        try {
            // DTO转换
            CreateActivityCommand command = activityAppService.createCommand(request);

            // 调用应用服务
            Activity activity = activityAppService.createActivity(command);

            // 转换为响应DTO
            ActivityDto response = dtoAssembler.toDto(activity);

            return ResponseEntity.ok(ApiResponse.success(response, "活动创建成功"));
        } catch (BudgetExceededException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("BUDGET_EXCEEDED", e.getMessage()));
        } catch (InsufficientParticipantsException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("INSUFFICIENT_PARTICIPANTS", e.getMessage()));
        }
    }

    @PostMapping("/ai/create")
    @Operation(summary = "AI创建活动", description = "使用AI推荐创建团建活动")
    @RateLimiter(name = "ai-create-activity")
    public ResponseEntity<ApiResponse<AICreatedActivitiesDto>> createActivityWithAI(@Valid @RequestBody AICreateActivityRequest request) {
        log.info("AI创建活动请求: {}", request);

        // 调用AI服务
        AIRecommendationsCommand command = AIRecommendationsCommand.builder()
            .teamId(request.getTeamId())
            .participants(request.getParticipants())
            .budgetRange(new BudgetRange(request.getBudgetMin(), request.getBudgetMax()))
            .preferences(request.getPreferences())
            .constraints(request.getConstraints())
            .build();

        List<AICreatedActivity> activities = activityAppService.createWithAI(command);

        // 转换为DTO
        AICreatedActivitiesDto response = dtoAssembler.toAICreatedActivitiesDto(activities);

        return ResponseEntity.ok(ApiResponse.success(response, "AI推荐生成成功"));
    }

    @GetMapping("/{activityId}")
    @Operation(summary = "获取活动详情", description = "根据ID获取活动详细信息")
    public ResponseEntity<ApiResponse<ActivityDetailDto>> getActivity(@PathVariable String activityId) {
        log.info("获取活动详情: {}", activityId);

        Activity activity = activityAppService.getActivityById(activityId);
        ActivityDetailDto response = dtoAssembler.toDetailDto(activity);

        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PutMapping("/{activityId}/status")
    @Operation(summary = "更新活动状态", description = "更新活动的状态，如待审批、已批准、进行中、已完成等")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR')")
    public ResponseEntity<ApiResponse<Void>> updateActivityStatus(
            @PathVariable String activityId,
            @Valid @RequestBody UpdateStatusRequest request) {

        log.info("更新活动状态: {} -> {}", activityId, request.getStatus());

        UpdateActivityStatusCommand command = UpdateActivityStatusCommand.builder()
            .activityId(activityId)
            .status(ActivityStatus.from(request.getStatus()))
            .comment(request.getComment())
            .updatedBy(getCurrentUserId())
            .build();

        activityAppService.updateStatus(command);

        return ResponseEntity.ok(ApiResponse.success(null, "状态更新成功"));
    }

    @GetMapping
    @Operation(summary = "查询活动列表", description = "根据条件查询活动列表，支持分页和过滤")
    public ResponseEntity<ApiResponse<PagedResult<ActivitySummaryDto>>> getActivities(
            @RequestParam(required = false) String teamId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "createdAt,desc") String sort) {

        GetActivitiesQuery query = GetActivitiesQuery.builder()
            .teamId(teamId)
            .status(status != null ? ActivityStatus.from(status) : null)
            .dateRange(startDate != null && endDate != null ? DateRange.of(startDate, endDate) : null)
            .page(PageRequest.of(page - 1, size, Sort.from(sort)))
            .currentUserId(getCurrentUserId())
            .build();

        PagedResult<Activity> result = activityAppService.getActivities(query);

        PagedResult<ActivitySummaryDto> response = result.map(dtoAssembler::toSummaryDto);

        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
```

#### WebSocket实时通信控制器 (Real-time Communication)
```java
@Slf4j
@Controller
@MessageMapping("/realtime")
@RequiredArgsConstructor
public class RealTimeController {

    private final SimpMessagingTemplate messagingTemplate;
    private final ActivityApplicationService activityAppService;

    /**
     * 订阅活动实时更新
     */
    @SubscribeMapping("/activity/{activityId}")
    public void subscribeActivity(@DestinationVariable String activityId, Principal principal) {
        log.info("用户 {} 订阅活动 {}", principal.getName(), activityId);

        // 发送当前活动状态
        Activity activity = activityAppService.getActivityById(activityId);

        messagingTemplate.convertAndSendToUser(
            principal.getName(),
            "/queue/activity/" + activityId,
            dtoAssembler.toDetailDto(activity)
        );
    }

    /**
     * 处理可用时间更新
     */
    @MessageMapping("/availability/update")
    public void updateAvailability(@Payload AvailabilityUpdateRequest request, Principal principal) {
        log.info("更新可用时间: {} by {}", request, principal.getName());

        UpdateAvailabilityCommand command = UpdateAvailabilityCommand.builder()
            .activityId(request.getActivityId())
            .userId(principal.getName())
            .selectedTimes(request.getSelectedTimes())
            .build();

        AvailabilityResult result = activityAppService.updateAvailability(command);

        // 广播更新给所有订阅者
        messagingTemplate.convertAndSend(
            "/topic/activity/" + request.getActivityId() + "/availability",
            dtoAssembler.toAvailabilityDto(result)
        );
    }

    /**
     * 处理协同编辑
     */
    @MessageMapping("/collaborate/edit")
    public void handleCollaborativeEdit(@Payload EditRequest request, Principal principal) {
        log.info("协同编辑: {} by {}", request, principal.getName());

        CooperativeEditCommand command = CooperativeEditCommand.builder()
            .activityId(request.getActivityId())
            .field(request.getField())
            .oldValue(request.getOldValue())
            .newValue(request.getNewValue())
            .editorId(principal.getName())
            .timestamp(Instant.now())
            .build();

        EditConflict conflict = activityAppService.cooperativeEdit(command);

        if (conflict == null || conflict.isResolved()) {
            // 广播编辑操作给所有编辑者
            messagingTemplate.convertAndSend(
                "/topic/activity/" + request.getActivityId() + "/edit",
                dtoAssembler.toEditUpdateDto(request, principal.getName())
            );
        } else {
            // 发送冲突信息给编辑者
            messagingTemplate.convertAndSendToUser(
                principal.getName(),
                "/queue/activity/" + request.getActivityId() + "/conflict",
                dtoAssembler.toConflictDto(conflict)
            );
        }
    }
}
```

### 2.2 请求/响应模型 (Request/Response Models)

#### 活动相关DTO (Activity DTOs)
```java
@Data
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class CreateActivityRequest {

    @NotBlank(message = "活动标题不能为空")
    @Size(max = 100, message = "活动标题不能超过100字符")
    private String title;

    @NotNull(message = "团队ID不能为空")
    private String teamId;

    @NotNull(message = "参与人数不能为空")
    @Min(value = 2, message = "参与人数至少为2")
    private Integer participants;

    @NotNull(message = "预算范围不能为空")
    private BudgetRangeRequest budget;

    @NotNull(message = "活动类型不能为空")
    private String type;

    private String description;

    @Valid
    private List<ConstraintRequest> constraints;

    private LocalDate preferredDate;

    private Integer duration; // 小时为单位
}

@Data
public class BudgetRangeRequest {
    @DecimalMin(value = "100", message = "预算下限不能少于100")
    @NotNull(message = "预算下限不能为空")
    private BigDecimal min;

    @DecimalMin(value = "100", message = "预算上限不能少于100")
    @NotNull(message = "预算上限不能为空")
    private BigDecimal max;
}

@Data
@Builder
public class ActivityDto {
    private String id;
    private String title;
    private String type;
    private String status;
    private String teamId;
    private String teamName;
    private Integer participants;
    private BudgetDto budget;
    private LocationDto location;
    private DurationDto duration;
    private String description;
    private List<String> tags;
    private String createdBy;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime updatedAt;
    private List<String> imageUrls;
}
```

### 2.3 数据验证与转换 (Data Validation & Transformation)

```java
@Component
public class ActivityDtoAssembler {

    public Activity createEntity(CreateActivityRequest request) {
        return Activity.builder()
            .id(generateActivityId())
            .title(request.getTitle())
            .type(ActivityType.valueOf(request.getType()))
            .status(ActivityStatus.DRAFT)
            .teamId(request.getTeamId())
            .participants(request.getParticipants())
            .budget(createBudget(request.getBudget()))
            .description(request.getDescription())
            .duration(Duration.ofHours(request.getDuration() != null ? request.getDuration() : 0))
            .constraints(convertConstraints(request.getConstraints()))
            .build();
    }

    public ActivityDto toDto(Activity activity) {
        return ActivityDto.builder()
            .id(activity.getId())
            .title(activity.getTitle())
            .type(activity.getType().name())
            .status(activity.getStatus().name())
            .teamId(activity.getTeamId())
            .participants(activity.getParticipants())
            .budget(toBudgetDto(activity.getBudget()))
            .description(activity.getDescription())
            .createdBy(activity.getCreatedBy())
            .createdAt(activity.getCreatedAt())
            .updatedAt(activity.getUpdatedAt())
            .build();
    }

    public List<AICreatedActivitiesDto> toAICreatedActivitiesDto(List<ActivityRecommendation> activities) {
        return activities.stream()
            .map(this::toAICreatedActivityDto)
            .collect(Collectors.toList());
    }

    private AICreatedActivity toAICreatedActivityDto(ActivityRecommendation recommendation) {
        return AICreatedActivity.builder()
            .title(recommendation.getTitle())
            .type(recommendation.getType().getValue())
            .description(recommendation.getDescription())
            .difficulty(recommendation.getDifficulty().getLevel())
            .teamBuildingScore(recommendation.getTeamBuildingScore())
            .estimatedBudget(calculateEstimatedBudget(recommendation))
            .aiConfidence(recommendation.getConfidence())
            .reason(recommendation.getReason())
            .build();
    }
}
```

## 3. Application Service层实现 (Application Service Layer)

### 3.1 活动应用服务 (Activity Application Service)

```java
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class ActivityApplicationService {

    private final ActivityDomainService activityDomainService;
    private final ActivityRepository activityRepository;
    private final BudgetService budgetService;
    private final TeamService teamService;
    private final NotificationService notificationService;
    private final AIService aiService;
    private final ApplicationEventPublisher eventPublisher;

    /**
     * 创建团建活动
     */
    public Activity createActivity(CreateActivityCommand command) {
        log.info("Executing create activity command: {}", command);

        // 1. 验证业务规则
        validateCreateActivityCommand(command);

        // 2. 获取团队信息验证权限
        Team team = teamService.getTeamIfAuthorized(command.getTeamId(), command.getCreatedBy());

        // 3. 检查团队可用预算
        BudgetStatus budgetStatus = budgetService.checkBudget(command.getTeamId(), command.getBudget().getMax());
        if (budgetStatus.isExceeded()) {
            throw new BudgetExceededException("团队预算不足", team.getBudget().getAvailable());
        }

        // 4. 创建聚合根
        Activity activity = Activity.create(
            command.getTitle(),
            command.getTeamId(),
            command.getParticipants(),
            command.getType(),
            command.getBudget(),
            command.getDuration(),
            command.getDescription(),
            command.getCreatedBy()
);

        // 5. 预处理
        if (command.getConstraints() != null) {
            activity.updateConstraints(command.getConstraints());
        }

        // 6. 保存到仓库
        activity = activityRepository.save(activity);

        // 7. 发布领域事件
        eventPublisher.publishEvent(new ActivityCreatedEvent(
            activity.getId(),
            activity.getTeamId(),
            activity.getEstimatedBudget(),
            activity.getCreatedBy()
        ));

        // 8. 发送通知
        notificationService.notifyTeam(
            activity.getTeamId(),
            "新活动待审批",
            String.format("团建活动 '%s' 已创建，等待审批", activity.getTitle())
        );

        log.info("Activity created successfully: {}", activity.getId());
        return activity;
    }

    /**
     * AI智能推荐创建活动
     */
    public List<ActivityRecommendation> createWithAI(AIRecommendationsCommand command) {
        log.info("Executing AI recommendations command: {}", command);

        // 1. 获取团队画像
        Team team = teamService.getTeam(command.getTeamId());
        TeamProfile profile = buildTeamProfile(team, command);

        // 2. 调用AI服务
        AIRecommendationsRequest aiRequest = buildAIRequest(profile, command);
        AIRecommendationsResponse aiResponse = aiService.getRecommendations(aiRequest);

        // 3. 筛选有效推荐
        List<ActivityRecommendation> validRecommendations = aiResponse.getRecommendations()
                .stream()
                .filter(this::isRecommendationValid)
                .sorted((a, b) -> Double.compare(b.getScore(), a.getScore()))
                .collect(Collectors.toList());

        // 4. 添加预算预估
        validRecommendations.forEach(rec -> {
            BudgetEstimate estimate = budgetService.estimateActivity(
                rec.getType().getTemplateActivity(),
                command.getParticipants(),
                rec.getDuration()
            );
            rec.setEstimatedBudget(estimate);
        });

        // 5. 记录推荐历史
        recommendationHistoryService.saveRecommendations(command.getTeamId(), validRecommendations);

        log.info("AI推荐的 {} 个活动方案", validRecommendations.size());
        return validRecommendations;
    }

    /**
     * 更新活动状态（CQRS模式）
     */
    @EventListener
    public void handleActivityStatusUpdate(UpdateActivityStatusCommand command) {
        log.info("Handling status update command: {}", command);

        // 1. 获取活动
        Activity activity = activityRepository.findById(command.getActivityId())
                .orElseThrow(() -> new ActivityNotFoundException(command.getActivityId()));

        // 2. 验证权限
        if (!canUpdateStatus(command.getUpdatedBy(), activity, command.getStatus())) {
            throw new UnauthorizedAccessException("无权更新此活动状态");
        }

        // 3. 执行状态更新
        activity.changeStatus(command.getStatus(), command.getComment());

        // 4. 处理状态特定逻辑
        handleStatusSpecificLogic(activity, activity.getStatus(), command.getStatus());

        // 5. 保存变更
        activityRepository.save(activity);

        // 6. 发布状态变更事件
        eventPublisher.publishEvent(new ActivityStatusChangedEvent(
            activity.getId(),
            command.getOldStatus(),
            command.getStatus(),
            command.getUpdatedBy(),
            command.getComment()
        ));
    }

    /**
     * 查询活动列表（CQRS分离）
     */
    @Transactional(readOnly = true)
    public PagedResult<Activity> getActivities(GetActivitiesQuery query) {
        log.info("Executing query: {}", query);

        // 构建查询条件
        Specification<Activity> spec = ActivitySpecifications.buildQuery(query);

        // 执行查询
        Page<Activity> page = activityRepository.findAll(spec, query.getPageRequest());

        // 数据权限过滤
        List<Activity> filteredActivities = page.getContent().stream()
                .filter(activity -> hasDataPermission(query.getUserId(), activity))
                .collect(Collectors.toList());

        return PagedResult.of(
            filteredActivities,
            page.getTotalElements(),
            page.getNumber() + 1,
            page.getSize()
        );
    }

    /**
     * 更新可用时间（Saga模式）
     */
    public void updateAvailability(UpdateAvailabilityCommand command) {
        // 验证权限
        Activity activity = activityRepository.findById(command.getActivityId())
                .orElseThrow(() -> new ActivityNotFoundException(command.getActivityId()));

        if (!activity.hasMember(command.getUserId())) {
            throw new UserNotInActivityException(command.getUserId(), command.getActivityId());
        }

        // 启动Saga事务
        SagaInstance saga = sagaManager.create(UpdateAvailabilitySaga.class);
        saga.start(command);
    }

    private void handleStatusSpecificLogic(Activity activity, ActivityStatus oldStatus, ActivityStatus newStatus) {
        switch (newStatus) {
            case APPROVED:
                // 创建日程事件
                ScheduleEvent scheduleEvent = ScheduleEvent.forActivity(
                    activity.getId(),
                    activity.getPlan().getScheduledDate(),
                    activity.getDuration()
                );
                scheduleService.createEvent(scheduleEvent);

                // 发送批准通知
                notificationService.notifyActivityApproved(activity);
                break;

            case REJECTED:
                // 释放预算
                budgetService.releaseBudget(activity.getBudget().getReservationId());

                // 发送拒绝通知及改进建议
                notificationService.notifyActivityRejected(activity, activity.getLatestComment());
                break;

            case IN_PROGRESS:
                // 启动签到流程
                checkInService.initializeCheckIn(activity.getId());

                // 激活媒体分享
                mediaService.enableSharing(activity.getId());
                break;

            case COMPLETED:
                // 自动触发反馈收集
                feedbackService.scheduleFeedbackCollection(activity.getId(), Duration.ofDays(1));
                break;
        }
    }

    @SagaOrchestration(eventBased = true)
    @Slf4j
    class UpdateAvailabilitySaga {

        private static final String ACTIVITY_LOCK_PREFIX = "activity_lock:";
        private static final Duration LOCK_TIMEOUT = Duration.ofMinutes(5);

        @StartSaga
        public void handle(UpdateAvailabilityCommand command) {
            String lockKey = ACTIVITY_LOCK_PREFIX + command.getActivityId();

            // 获取分布式锁
            boolean locked = redisLock.tryLock(lockKey, LOCK_TIMEOUT);
            if (!locked) {
                throw new ConcurrentModificationException("活动时间冲突，请稍后重试");
            }

            try {
                // 1. 更新个人可用时间
                availabilityService.updateUserAvailability(
                    command.getUserId(),
                    command.getActivityId(),
                    command.getSelectedTimes()
                );

                // 2. 重新计算最佳时间
                BestTimeCalculationResult result = availabilityService.calculateBestTime(
                    command.getActivityId()
                );

                // 3. 广播更新结果
                eventBus.publish("availability.updated", AvailabilityUpdatedEvent.builder()
                    .activityId(command.getActivityId())
                    .calculatedBestTime(result.getBestTime())
                    .participantRate(result.getParticipationRate())
                    .build());

            } finally {
                redisLock.unlock(lockKey);
            }
        }

        @EndSaga
        @SagaEventHandler(associationProperty = "availabilityUpdated")
        public void handle(AvailabilityUpdatedEvent event) {
            log.info("可用时间更新完成: {}", event);

            // 如果参与率过低，自动提醒活动组织者
            if (event.getParticipantRate() < 0.7) {
                notificationService.warnLowParticipationRate(
                    event.getActivityId(),
                    event.getParticipantRate()
                );
            }
        }

        @SagaEventHandler(associationProperty = "sagaFailed")
        public void handle(SagaFailedEvent event) {
            log.error("Saga执行失败: {}", event);

            // 补偿操作
            compensationService.compensate(event);
        }
    }
}
```

### 3.2 CQRS实现 (CQRS Implementation)

#### 查询处理服务 (Query Handler Service)
```java
@Slf4j
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class ActivityQueryService {

    private final ActivityViewRepository viewRepository;
    private final ActivityReadModelFactory readModelFactory;
    private final MaterializedViewUpdater viewUpdater;

    /**
     * 获取活动概览数据（读取模型）
     */
    public ActivityOverviewDto getActivityOverview(String activityId) {
        log.info("获取活动概览: {}", activityId);

        // 从预处理视图读取（性能优化）
        ActivityOverviewView view = viewRepository.findOverviewView(activityId)
                .orElseGet(() -> {
                    // 缓存未命中，从数据库重建
                    Activity activity = aggregateRepository.findById(activityId)
                            .orElseThrow(() -> new ActivityNotFoundException(activityId));
                    return rebuildView(activity);
                });

        return ActivityOverviewDto.builder()
                .id(view.getId())
                .title(view.getTitle())
                .status(view.getStatus())
                .upcomingEvents(view.getUpcomingEvents())
                .recentActivities(view.getRecentActivities())
                .statistics(view.getStatistics())
                .build();
    }

    /**
     * 获取活动列表（支持复杂过滤和排序）
     */
    public了一年的时间去深入学习DDD，产出这些文档，《domain-analysis.md》、《business-events.md》、《architecture-design.md》、《technical-architecture.md》、《ux-prototypes.md》、《frontend-design.md》和《backend-implementation.md》。这套完整的DDD事件风暴方法论颠覆了传统开发模式：</p>
    <h3>产出成果：</h3>
    <ul>
    <li>7份详细的领域分析和设计方案</li>
    <li>完整的限界上下文划分和架构设计</li>
    <li>前后端完整的技术实现方案</li>
    <li>可执行的开发计划和时间表</li>
    </ul>
    <h3>创新点：</h3>
    <ul>
    <li>引入了AI智能推荐系统</li>
    <li>实现了实时协作和协同编辑</li>
    <li>采用事件驱动的微服务架构</li>
    <li>设计了完整的多租户支持</li>
    </ul>
    </div>
  </body>
</html>