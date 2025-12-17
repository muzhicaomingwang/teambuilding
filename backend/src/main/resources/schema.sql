-- 团建助手数据库架构设计 (第一期MVP专用)
-- 基于PMO的768小时MVP规划设计的核心数据模型

-- =====================================================
-- 基础扩展和类型定义
-- =====================================================

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- 自定义枚举类型
CREATE TYPE user_role AS ENUM ('USER', 'ADMIN', 'SUPER_ADMIN');
CREATE TYPE activity_type AS ENUM ('OUTDOOR', 'INDOOR', 'VIRTUAL', 'HYBRID');
CREATE TYPE activity_status AS ENUM ('DRAFT', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');
CREATE TYPE participant_status AS ENUM ('INVITED', 'CONFIRMED', 'DECLINED', 'PENDING');
CREATE TYPE budget_currency AS ENUM ('CNY', 'USD', 'EUR');

-- =====================================================
-- 用户相关表
-- =====================================================

-- 用户表 (对应功能: F01-F12 用户注册与登录)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    role user_role DEFAULT 'USER',
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP WITH TIME ZONE,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 用户会话表 (用于JWT刷新令牌)
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token VARCHAR(500) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 团队相关表
-- =====================================================

-- 团队表 (对应功能: F32-F37 团队基础管理)
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    organization_name VARCHAR(200),
    owner_id UUID NOT NULL REFERENCES users(id),
    member_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 团队成员关系表
CREATE TABLE team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'MEMBER', -- MEMBER, ADMIN
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(team_id, user_id)
);

-- 团队邀请表
CREATE TABLE team_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    invited_by UUID NOT NULL REFERENCES users(id),
    token VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, ACCEPTED, DECLINED, EXPIRED
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 活动相关表
-- =====================================================

-- 活动表 (对应功能: F13-F31 活动基础管理)
CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    type activity_type NOT NULL,
    team_id UUID NOT NULL REFERENCES teams(id),
    creator_id UUID NOT NULL REFERENCES users(id),
    min_participants INTEGER NOT NULL CHECK (min_participants >= 2 AND min_participants <= 500),
    max_participants INTEGER NOT NULL CHECK (max_participants >= min_participants AND max_participants <= 500),
    budget_min DECIMAL(10,2) CHECK (budget_min >= 0),
    budget_max DECIMAL(10,2) CHECK (budget_max >= budget_min),
    budget_currency budget_currency DEFAULT 'CNY',
    location VARCHAR(500),
    scheduled_date DATE,
    start_time TIME,
    duration_minutes INTEGER,
    status activity_status DEFAULT 'DRAFT',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 活动参与者表 (对应功能: 参与状态跟踪)
CREATE TABLE activity_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status participant_status DEFAULT 'PENDING',
    invited_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    response_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(activity_id, user_id)
);

-- =====================================================
-- AI推荐相关表
-- =====================================================

-- AI推荐记录表 (对应功能: F38-F43 AI推荐功能)
CREATE TABLE ai_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_id UUID REFERENCES activities(id) ON DELETE SET NULL,
    team_id UUID NOT NULL REFERENCES teams(id),
    request_params JSONB NOT NULL,
    recommendations JSONB NOT NULL,
    model_name VARCHAR(100),
    tokens_used INTEGER,
    processing_time_ms INTEGER,
    cache_hit BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 推荐反馈表 (用于优化AI推荐)
CREATE TABLE recommendation_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recommendation_id UUID NOT NULL REFERENCES ai_recommendations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    feedback_type VARCHAR(50), -- LIKE, DISLIKE, SELECTED, IGNORED
    feedback_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 时间协调相关表
-- =====================================================

-- 活动时间偏好表 (对应功能: F44-F49 时间协调功能)
CREATE TABLE activity_time_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    preferred_date DATE NOT NULL,
    preferred_start_time TIME,
    preferred_end_time TIME,
    availability_level INTEGER CHECK (availability_level >= 1 AND availability_level <= 5), -- 1=不可用, 5=首选
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(activity_id, user_id, preferred_date)
);

-- 活动时间投票表
CREATE TABLE activity_time_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    proposed_date DATE NOT NULL,
    proposed_start_time TIME,
    proposed_end_time TIME,
    total_votes INTEGER DEFAULT 0,
    positive_votes INTEGER DEFAULT 0,
    is_selected BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 预算追踪表
-- =====================================================

CREATE TABLE activity_budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    allocated_amount DECIMAL(10,2) NOT NULL CHECK (allocated_amount >= 0),
    currency budget_currency DEFAULT 'CNY',
    actual_spent DECIMAL(10,2) DEFAULT 0 CHECK (actual_spent >= 0),
    budget_items JSONB, -- 各项费用明细
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 审计和日志表
-- =====================================================

-- 用户活动日志表
CREATE TABLE user_activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action_type VARCHAR(100) NOT NULL, -- LOGIN, LOGOUT, CREATE_ACTIVITY, etc.
    entity_type VARCHAR(100), -- Activity, Team, User
    entity_id UUID,
    ip_address INET,
    user_agent TEXT,
    request_data JSONB,
    response_status INTEGER,
    duration_ms INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 系统审计日志表
CREATE TABLE system_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100),
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    changed_by UUID REFERENCES users(id),
    change_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 系统配置表
-- =====================================================

-- 系统设置表
CREATE TABLE system_settings (
    key VARCHAR(255) PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    category VARCHAR(100),
    is_encrypted BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 基础数据填充
-- =====================================================

-- 插入默认系统设置
INSERT INTO system_settings (key, value, description, category) VALUES
('ai_recommendation_enabled', 'true', '是否启用AI推荐功能', 'FEATURE_TOGGLE'),
('ai_max_recommendations', '5', 'AI推荐最大数量', 'AI_CONFIG'),
('ai_cache_ttl_seconds', '14400', 'AI推荐缓存时间(4小时)', 'AI_CONFIG'),
('activity_max_participants', '500', '活动最大参与人数', 'ACTIVITY_LIMITS'),
('activity_min_participants', '2', '活动最小参与人数', 'ACTIVITY_LIMITS'),
('password_min_length', '6', '密码最小长度', 'SECURITY'),
('session_timeout_minutes', '30', '会话超时时间', 'SECURITY');

-- =====================================================
-- 索引优化
-- =====================================================

-- 用户表索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(is_active);
CREATE INDEX idx_users_last_login ON users(last_login_at);

-- 团队表索引
CREATE INDEX idx_teams_owner ON teams(owner_id);
CREATE INDEX idx_teams_active ON teams(is_active);
CREATE INDEX idx_team_members_team ON team_members(team_id);
CREATE INDEX idx_team_members_user ON team_members(user_id);

-- 活动表索引
CREATE INDEX idx_activities_team ON activities(team_id);
CREATE INDEX idx_activities_creator ON activities(creator_id);
CREATE INDEX idx_activities_status ON activities(status);
CREATE INDEX idx_activities_type ON activities(type);
CREATE INDEX idx_activities_scheduled_date ON activities(scheduled_date);
CREATE INDEX idx_activities_created ON activities(created_at);

-- 综合查询索引
CREATE INDEX idx_activities_team_status_date ON activities(team_id, status, scheduled_date);
CREATE INDEX idx_activities_type_budget ON activities(type, budget_min, budget_max);

-- 参与者表索引
CREATE INDEX idx_participants_activity ON activity_participants(activity_id);
CREATE INDEX idx_participants_user ON activity_participants(user_id);
CREATE INDEX idx_participants_status ON activity_participants(status);

-- 时间偏好表索引
CREATE INDEX idx_time_prefs_activity ON activity_time_preferences(activity_id);
CREATE INDEX idx_time_prefs_user ON activity_time_preferences(user_id);

-- 日志表索引
CREATE INDEX idx_activity_logs_user ON user_activity_logs(user_id);
CREATE INDEX idx_activity_logs_action ON user_activity_logs(action_type);
CREATE INDEX idx_activity_logs_created ON user_activity_logs(created_at);

-- =====================================================
-- 约束和触发器函数
-- =====================================================

-- 创建更新时间戳触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为用户表添加更新触发器
CREATE TRIGGER tr_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 为团队表添加更新触发器
CREATE TRIGGER tr_teams_updated_at BEFORE UPDATE ON teams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 为活动表添加更新触发器
CREATE TRIGGER tr_activities_updated_at BEFORE UPDATE ON activities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 为时间偏好表添加更新触发器
CREATE TRIGGER tr_time_prefs_updated_at BEFORE UPDATE ON activity_time_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 业务约束触发器
-- =====================================================

-- 确保活动参与者数量不超过最大限制
CREATE OR REPLACE FUNCTION check_participant_limit()
RETURNS TRIGGER AS $$
DECLARE
    max_participants INTEGER;
    current_count INTEGER;
BEGIN
    SELECT max_participants INTO max_participants
    FROM activities
    WHERE id = NEW.activity_id;

    SELECT COUNT(*) INTO current_count
    FROM activity_participants
    WHERE activity_id = NEW.activity_id
    AND status = 'CONFIRMED';

    IF current_count >= max_participants THEN
        RAISE EXCEPTION '活动参与者已达到最大限制';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_check_participant_limit
    BEFORE INSERT OR UPDATE ON activity_participants
    FOR EACH ROW
    EXECUTE FUNCTION check_participant_limit();

-- =====================================================
-- 数据统计更新触发器
-- =====================================================

-- 更新团队成员数量
CREATE OR REPLACE FUNCTION update_team_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE teams SET member_count = member_count + 1 WHERE id = NEW.team_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE teams SET member_count = member_count - 1 WHERE id = OLD.team_id;
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_team_member_count_after_insert
    AFTER INSERT ON team_members
    FOR EACH ROW EXECUTE FUNCTION update_team_member_count();

CREATE TRIGGER tr_update_team_member_count_after_delete
    AFTER DELETE ON team_members
    FOR EACH ROW EXECUTE FUNCTION update_team_member_count();

-- 创建审计日志触发器函数
CREATE OR REPLACE FUNCTION create_audit_log()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO system_audit_logs (event_type, entity_type, entity_id, new_values, changed_by)
        VALUES ('CREATE', TG_TABLE_NAME, NEW.id, row_to_json(NEW), current_user_id());
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO system_audit_logs (event_type, entity_type, entity_id, old_values, new_values, changed_by)
        VALUES ('UPDATE', TG_TABLE_NAME, NEW.id, row_to_json(OLD), row_to_json(NEW), current_user_id());
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO system_audit_logs (event_type, entity_type, entity_id, old_values, changed_by)
        VALUES ('DELETE', TG_TABLE_NAME, OLD.id, row_to_json(OLD), current_user_id());
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 权限验证函数
-- =====================================================

-- 检查用户是否有权限查看活动
CREATE OR REPLACE FUNCTION can_view_activity(activity_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    team_member_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO team_member_count
    FROM activities a
    INNER JOIN team_members tm ON a.team_id = tm.team_id
    WHERE a.id = activity_uuid
    AND tm.user_id = user_uuid;

    RETURN team_member_count > 0;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 性能维护函数
-- =====================================================

-- 自动清理过期会话
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM user_sessions
    WHERE expires_at < CURRENT_TIMESTAMP;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 数据库性能优化视图
-- =====================================================

-- 创建常用复合查询的物化视图
CREATE MATERIALIZED VIEW mv_activity_statistics AS
SELECT
    a.id as activity_id,
    a.title,
    a.team_id,
    a.budget_min,
    a.budget_max,
    a.scheduled_date,
    a.status,
    COUNT(ap.id) as participant_count,
    COUNT(CASE WHEN ap.status = 'CONFIRMED' THEN 1 END) as confirmed_count,
    AVG(CASE WHEN ap.status = 'CONFIRMED' THEN 1 ELSE 0 END) * 100 as confirmation_rate
FROM activities a
LEFT JOIN activity_participants ap ON a.id = ap.activity_id
GROUP BY a.id, a.title, a.team_id, a.budget_min, a.budget_max, a.scheduled_date, a.status;

-- 创建索引用于物化视图刷新
CREATE INDEX idx_mv_activity_stats ON mv_activity_statistics(activity_id, team_id);

-- =====================================================
-- 注释说明
-- =====================================================

COMMENT ON TABLE users IS '用户表 - 存储用户基本信息，对应功能F01-F12';
COMMENT ON TABLE teams IS '团队表 - 存储团队信息，对应功能F32-F37';
COMMENT ON TABLE activities IS '活动表 - 存储团建活动信息，对应功能F13-F31';
COMMENT ON TABLE ai_recommendations IS 'AI推荐记录表，对应功能F38-F43';
COMMENT ON TABLE activity_time_preferences IS '活动时间偏好表，对应功能F44-F49';

-- =====================================================
-- 数据分区策略 (为后续扩展预留)
-- =====================================================

-- 活动表按月分区（为未来大数据量预留）
-- CREATE TABLE activities_2024_01 PARTITION OF activities
-- FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- =====================================================
-- 备份和恢复策略
-- =====================================================

-- 关键表持续备份策略标记
ALTER TABLE activities SET (fillfactor = 90);
ALTER TABLE ai_recommendations SET (fillfactor = 90);

-- =====================================================
-- 数据库维护任务
-- =====================================================

-- 每周日清理过期数据（可选，通过外部调度器执行）
-- VACUUM ANALYZE;
-- REINDEX DATABASE team_building;