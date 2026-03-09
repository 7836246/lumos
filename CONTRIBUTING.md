# 🤝 贡献指南

感谢你对 **Lumos · 契光鉴微** 的关注！无论你是开发者、法律工作者还是普通打工人，你的每一份贡献都在帮助更多的人避免合同陷阱。

## 📋 目录

- [如何贡献](#如何贡献)
- [开发环境搭建](#开发环境搭建)
- [提交规范](#提交规范)
- [Pull Request 流程](#pull-request-流程)
- [Issue 规范](#issue-规范)
- [项目结构](#项目结构)
- [行为准则](#行为准则)

---

## 如何贡献

### 💻 开发者

- 🐛 修复 Bug 或优化性能
- ✨ 实现新功能
- 📝 完善文档和注释
- 🧪 编写测试用例
- 🌐 国际化 / 多语言支持

### ⚖️ 法律从业者

- 📚 补充劳动法判例和条款库
- 🔍 优化风险检测规则和阈值
- 📋 审查 AI 输出话术的法律准确性

### 🧑‍💼 普通用户

- 💬 提交你遇到的合同坑点 Issue
- ⭐ 给项目点一个 Star
- 📢 分享给身边需要的朋友

---

## 开发环境搭建

### 客户端 (Flutter)

```bash
# 确保已安装 Flutter 3.x+
flutter --version

# 进入客户端目录
cd client

# 安装依赖
flutter pub get

# 运行 (以 Chrome 为例)
flutter run -d chrome
```

### 服务端 (Python) — 规划中

```bash
# 确保 Python 3.12+
python --version

# 进入服务端目录
cd backend

# 创建虚拟环境
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt

# 启动开发服务器
uvicorn app.main:app --reload
```

---

## 提交规范

我们使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Type 类型

| 类型 | 说明 |
|:---|:---|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档变更 |
| `style` | 代码格式（不影响功能） |
| `refactor` | 代码重构 |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建/辅助工具变动 |
| `ci` | CI/CD 配置 |

### Scope 范围

- `client` — Flutter 客户端相关
- `server` — Python 服务端相关
- `docs` — 文档
- `legal` — 法律条款库

### 示例

```
feat(client): 添加合同拍照扫描页面

- 集成 camera 插件
- 实现拍照预览与裁剪
- 添加 ML Kit OCR 识别

Closes #12
```

---

## Pull Request 流程

1. **Fork** 本仓库
2. 从 `main` 创建特性分支：`git checkout -b feat/your-feature`
3. 编写代码并提交（遵循提交规范）
4. 确保本地测试通过
5. 提交 PR 到 `main` 分支
6. 填写 PR 模板，描述你的变更
7. 等待 Code Review 和 CI 检查

### PR 检查清单

- [ ] 代码符合项目编码规范
- [ ] 已添加/更新必要的测试
- [ ] 已更新相关文档
- [ ] commit message 符合规范
- [ ] 无 lint 错误

---

## Issue 规范

### 🐛 Bug 报告

请包含以下信息：

- 环境信息（OS、Flutter 版本、设备等）
- 复现步骤
- 期望行为 vs 实际行为
- 截图或错误日志（如适用）

### ✨ 功能建议

请描述：

- 使用场景和动机
- 期望的解决方案
- 备选方案（如有）

### 📚 法律条款贡献

请提供：

- 相关法律条款原文及来源
- 对应的风险等级建议
- 适用场景说明

---

## 项目结构

```
lumos/
├── client/          # Flutter 客户端
│   └── lib/
│       ├── core/       # 主题、路由、API
│       ├── features/   # 业务功能模块
│       └── shared/     # 公共组件
├── backend/         # Python 服务端 (规划中)
├── docs/            # 项目文档
└── public/          # 静态资源
```

---

## 行为准则

参与本项目即表示你同意遵守我们的 [行为准则](./CODE_OF_CONDUCT.md)。

我们致力于营造一个开放、包容、友善的社区环境。

---

<p align="center">
  <strong>💛 每一份贡献，都在帮助更多打工人免于合同陷阱</strong>
</p>
