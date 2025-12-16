# Team Building Assistant

A comprehensive tool to help organizations plan, manage, and execute team building activities effectively.

## 中文介绍 (Chinese Introduction)

这个项目是一个团建助手，旨在帮助组织更好地规划、管理和执行团队建设活动。

## Features

- **AI-Powered Activity Planning**: Generate personalized team building activities using Claude AI
- Activity planning and management
- Team member coordination
- Budget tracking
- Feedback collection
- Photo/video sharing
- Schedule management

## Prerequisites

- Node.js 16+ installed
- Anthropic Claude API key (get one at [anthropic.com](https://anthropic.com))

## Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/team-building-assistant.git
cd team-building-assistant
```

2. Install dependencies:
```bash
npm install
```

3. Set up your environment variables:
   - Copy the `.env` file and add your Anthropic API key:
   ```bash
   VITE_ANTHROPIC_API_KEY=your_actual_api_key_here
   ```

## Usage

1. Start the development server:
```bash
npm run dev
```

2. Open your browser and go to `http://localhost:5173`

3. Use the Team Building Assistant section to:
   - Enter team size, budget, and preferences
   - Generate AI-powered activity suggestions
   - Get personalized recommendations based on your team needs

## Building for Production

```bash
npm run build
npm run preview
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Event Storming Session - Team Building Assistant

This project implements a comprehensive event storming approach based on Domain-Driven Design (DDD) principles, involving 7 specialized roles to ensure thorough analysis and design.

### Event Storming Overview

Event storming is a rapid, lightweight workshop method for exploring complex business domains. For the Team Building Assistant project, we've conducted a comprehensive event storming session with multiple expert roles.

### The 7 Roles in Our Event Storming

1. **DDD领域驱动设计专家** - Facilitates the event storming process and produces final domain analysis
2. **业务专家** - Identifies all business events and processes
3. **架构专家** - Designs architecture based on bounded contexts and interactions
4. **技术专家** - Provides technical architecture design
5. **设计师** - Creates prototypes and interaction designs
6. **前端工程师** - Designs frontend implementation
7. **后端工程师** - Implements backend layers (Adapter → Application → Domain → Repository)

#### **新增角色（第2轮事件风暴）**

8. **QA质量保证专家** - Ensures system quality, reliability and compliance through testing
9. **OPS运维专家** - Manages infrastructure, deployment, monitoring and 24/7 operations
10. **DBA数据库管理员** - Designs database architecture, performance optimization and data management

### Event Storming Outputs

The event storming session produces detailed documentation in the `/docs/event-storming/` directory:

#### 1. DDD领域驱动设计专家 Output (`/docs/event-storming/domain-analysis.md`)
**Contains:**
- **Domain Division**: Core domains, supporting domains, generic domains
- **Bounded Contexts**: Clear boundaries and contexts identification
- **Domain Entities**: All identified entities with their relationships
- **Value Objects**: Immutable value objects within the domain
- **Domain Events**: All business events that trigger state changes

#### 2. 业务专家 Output (`/docs/event-storming/business-events.md`)
**Contains:**
- Complete list of all business events
- Event sequences and workflows
- Business rules associated with events
- Actor identification (who triggers what)
- Event causality chains

#### 3. 架构专家 Output (`/docs/event-storming/architecture-design.md`)
**Contains:**
- **Intra-domain Architecture**: Patterns within each bounded context
- **Inter-domain Architecture**: Integration patterns between bounded contexts
- **Context Mapping**: Relationship types between contexts (Partnership, Shared Kernel, etc.)
- **Communication Patterns**: Synchronous vs asynchronous communication
- **Service Boundaries**: Microservices or modular monolith decisions

#### 4. 技术专家 Output (`/docs/event-storming/technical-architecture.md`)
**Contains:**
- Technology stack selection rationale
- Infrastructure architecture (cloud/on-premise/hybrid)
- Database design and data persistence strategy
- API design patterns (REST/GraphQL/gRPC)
- Security architecture
- Performance and scalability considerations

#### 5. 设计师 Output (`/docs/event-storming/ux-prototypes.md`)
**Contains:**
- User journey mapping
- Wireframes for all key screens
- Interaction flow designs
- Visual design guidelines
- Accessibility considerations
- Mobile-responsive design approach

#### 6. 前端工程师 Output (`/docs/event-storming/frontend-design.md`)
**Contains:**
- Frontend framework selection
- Component architecture
- State management strategy
- Build and deployment pipeline
- Performance optimization strategies
- Testing strategy (unit, integration, e2e)

#### 7. 后端工程师 Output (`/docs/event-storming/backend-implementation.md`)
**Contains detailed implementation of each layer:**
- **Adapter Layer**: REST API endpoints, message consumers, external service integrations
- **Application Service Layer**: Use cases, command/query handling, workflow orchestration
- **Domain Layer**: Domain services, domain events, business logic implementation
- **Repository Layer**: Data access patterns, ORM models, queries, transactions

### Key Bounded Contexts Identified

1. **Activity Planning Context**: Core domain for planning activities
2. **Team Coordination Context**: Managing team members and communications
3. **Budget Management Context**: Handling financial aspects
4. **Feedback and Analytics Context**: Collecting and analyzing feedback
5. **Media Sharing Context**: Managing photos/videos from activities
6. **Scheduling Context**: Time management and calendar integration

### Running the Event Storming Workshop

To reproduce or continue the event storming session:

1. **Setup**: Prepare a large wall or digital board (Miro/Mural)
2. **Materials**: Sticky notes in different colors for:
   - Orange: Domain events
   - Blue: Commands
   - Yellow: Aggregates/Entities
   - Green: Bounded contexts
   - Purple: External systems
3. **Participants**: Involve all 7 roles in the workshop
4. **Timeline**: Allow 2-4 hours for initial storming
5. **Documentation**: Capture all outputs in the `/docs/event-storming/` directory

### Next Steps After Event Storming

1. Implement the domain model based on the analysis
2. Create a project structure following the bounded contexts
3. Develop incrementally, starting with the core domain
4. Continuously validate with domain experts
5. Refine based on feedback and new insights

## License

This project is licensed under the MIT License.