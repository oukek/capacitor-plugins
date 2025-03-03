# @oukek/capacitor-plugins

这是一个 Capacitor 插件的 monorepo 项目，提供了多个可在 Quasar 中使用的插件。

## 项目结构

```
capacitor-plugins/
├── docs/           # 插件开发文档
├── example/        # 插件使用示例
├── packages/       # 插件源码
│   └── photo/     # 相册相关插件
└── package.json
```

## 开发环境设置

### 前置要求

- Node.js 20.x 或更高版本
- pnpm 8.x 或更高版本
- Git

### 安装

```bash
# 克隆仓库
git clone https://github.com/oukek/capacitor-plugins.git
cd capacitor-plugins

# 安装依赖
pnpm install
```

## 开发流程

### 1. 创建新插件

在 `packages` 目录下创建新的插件目录：

```bash
cd packages
mkdir my-plugin
cd my-plugin
pnpm init
```

### 2. 开发

```bash
# 构建所有插件
pnpm build

# 清理构建文件
pnpm clean

# 代码格式化
pnpm fmt

# 代码检查
pnpm lint
```

### 3. 提交规范

我们使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范来格式化提交信息。

提交类型：
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式修改
- `refactor`: 代码重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

示例：
```bash
# 新功能
git commit -m "feat(photo): add image compression feature"

# Bug 修复
git commit -m "fix(photo): handle image rotation correctly"

# 破坏性更改
git commit -m "feat(photo)!: change upload API interface"
```

### 4. 版本发布流程

我们使用 [changesets](https://github.com/changesets/changesets) 来管理版本和发布。

#### 创建变更集

当你完成一个功能或修复时：

```bash
# 创建变更集
pnpm changeset

# 按提示选择：
# 1. 选择要发布的包
# 2. 选择版本更新类型
#    - patch: 修复
#    - minor: 新功能
#    - major: 破坏性更改
# 3. 输入变更说明
```

这会在 `.changeset` 目录下创建一个 markdown 文件，需要将它提交到仓库。

#### 发布流程

1. 提交代码和变更集：
   ```bash
   git add .
   git commit -m "feat: your changes"
   git push
   ```

2. GitHub Actions 会自动：
   - 创建一个 "Version Packages" PR
   - PR 包含版本更新和 changelog 变更
   - 合并 PR 后自动发布到 npm

## 示例

### 开发新功能

```bash
# 1. 创建功能分支
git checkout -b feature/new-feature

# 2. 开发功能并测试
pnpm build
pnpm lint

# 3. 创建变更集
pnpm changeset
# 选择包和版本类型，输入变更说明

# 4. 提交代码
git add .
git commit -m "feat(photo): add new feature"
git push origin feature/new-feature

# 5. 创建 Pull Request
# 6. 代码审查并合并
# 7. 自动发布
```

### Bug 修复

```bash
# 1. 创建修复分支
git checkout -b fix/bug-fix

# 2. 修复 bug 并测试
pnpm build
pnpm lint

# 3. 创建变更集
pnpm changeset
# 选择包和版本类型（通常是 patch），输入变更说明

# 4. 提交代码
git add .
git commit -m "fix(photo): fix specific bug"
git push origin fix/bug-fix

# 5. 创建 Pull Request
# 6. 代码审查并合并
# 7. 自动发布
```

## 插件列表

### @oukek/capacitor-photo

相册相关插件，提供图片保存等功能。

[查看文档](./docs/photo/README.md)

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 许可证

MIT 