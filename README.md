# GitMsgAI 🚀

> **AI 驱动的 Git 自动化 Commit Message 生成 CLI 工具**  
> 智能分析 Git 暂存区改动（Staged Diff），遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范，一键生成高质量提交说明。

---

## ✨ 核心特性

- 🤖 **多 AI 提供商原生支持**：
  - **DeepSeek**（默认推荐，模型 `deepseek-chat`，超高性价比）
  - **Google Gemini**（原生 Google Generative Language REST API，模型 `gemini-2.5-flash` 等）
  - **OpenAI Compatible**（支持官方 OpenAI、Azure 代理、Ollama、Groq、OneAPI 等任何兼容网关，模型 `gpt-4o-mini`、`gpt-4o` 等）
- 📝 **Conventional Commits 规范**：严格按 `feat`、`fix`、`docs`、`refactor`、`chore` 等类型组织，支持可选 scope 与详细列表说明。
- 🌐 **双语支持**：一键切换中文（`--lang zh`）或英文（`--lang en`）。
- 🎨 **Gitmoji 风格**：支持添加语义化 Git Emoji（如 `✨ feat:`, `🐛 fix:`）。
- 🖥️ **交互式工作流**：在终端提供直接提交 `[y]`、交互编辑 `[e]`、带有补充提示的重新生成 `[r]` 或取消 `[n]`。
- ⚡ **无依赖/独立原生二进制**：支持通过 `dart compile exe` 编译为无外部 Dart 运行时依赖的单文件机器码可执行文件。
- 🔒 **安全性与长 Diff 保护**：敏感 API Key 自动脱敏展示；超长代码差异自动智能保留统计摘要并平滑截断，避免超出大模型上下文。

---

## 📦 安装与编译

### 方式一：直接下载预编译二进制（推荐）
前往 [GitHub Releases](https://github.com/deskangel/gitmsgai/releases) 页面下载适合您系统的发行包：
- **Windows**: `gitmsgai-windows-x64.zip`（解压后将 `gitmsgai.exe` 加入系统 PATH）
- **macOS**: `gitmsgai-macos-arm64.tar.gz`（解压并将 `gitmsgai` 放置于 `/usr/local/bin` 或 `~/.local/bin`）
- **Linux**: `gitmsgai-linux-x64.tar.gz` 或 `gitmsgai-linux-arm64.tar.gz`

### 方式二：使用自动化构建脚本
```bash
# 执行完整构建（代码格式校验、静态分析、单元测试、编译为原生二进制）
./build.sh

# 编译并直接安装到系统路径（~/.local/bin 或 /usr/local/bin）
./build.sh --install

# 快速编译模式（跳过测试与代码检查）
./build.sh --fast

# 交叉编译 Linux 架构版本（x64 & arm64）
./build.sh --linux
```

### 方式三：直接使用 Dart 运行
```bash
dart run bin/gitmsgai.dart --help
```

### 方式四：全局注册为 Dart 命令行工具
```bash
dart pub global activate --source path .
```

---

## ⚙️ 快速配置

### 1. 配置 API Key（持久化至 `~/.config/gitmsgai/config.json`）

#### DeepSeek
```bash
gitmsgai config set deepseek.api_key sk-your-deepseek-key
gitmsgai config set default_provider deepseek
```

#### Google Gemini
```bash
gitmsgai config set gemini.api_key your-gemini-api-key
gitmsgai config set default_provider gemini
```

#### OpenAI 或第三方兼容接口
```bash
gitmsgai config set openai.api_key sk-your-openai-key
gitmsgai config set openai.base_url https://api.openai.com/v1
gitmsgai config set openai.model gpt-4o-mini
```

### 2. 查看当前生效配置
```bash
gitmsgai config list
```

---

## 🚀 使用指南

### 1. 标准交互式提交
```bash
# 1. 暂存代码
git add .

# 2. 运行 gitmsgai
gitmsgai
```
终端将自动输出待提交文件、AI 进度条、格式化后的 Commit Message，并等待选择：
```text
Staged files (2):
  [M] lib/src/git_service.dart
  [A] test/git_service_test.dart

✓ Generating with deepseek (deepseek-chat)
┌────────────────────────────────────────────────────────────┐
│ Proposed Commit Message:                                   │
├────────────────────────────────────────────────────────────┤
│ feat(git): 增加长差异智能截断与暂存文件状态检测             │
└────────────────────────────────────────────────────────────┘

Action: [y]es, commit | [e]dit | [r]egenerate | [n]o, cancel
Choice [y/e/r/n] (default: y): 
```

### 2. 常用命令行参数

| 参数 | 缩写 | 说明 | 示例 |
|---|---|---|---|
| `--provider` | `-p` | 切换 AI 提供商 (`deepseek`, `gemini`, `openai`) | `-p gemini` |
| `--model` | `-m` | 临时覆盖模型名称 | `-m deepseek-reasoner` |
| `--api-key` | `-k` | 临时指定 API Key | `-k sk-xxx` |
| `--lang` | `-l` | 提交语言 (`zh` 或 `en`) | `-l en` |
| `--emoji` | `-e` | 启用 Gitmoji | `-e` |
| `--detailed`| `-d` | 生成带列表的详细描述 | `-d` |
| `--auto-commit` | `-c` | 跳过交互询问直接提交 | `-c` |
| `--raw` | `-r` | 仅输出提交内容（用于脚本） | `-r` |
| `--hint` | | 向 AI 提供额外上下文提示 | `--hint "修复 #123 内存泄露"` |

### 3. 场景示例

#### 使用 Gemini 生成英文 Commit Message
```bash
gitmsgai -p gemini -l en
```

#### 带有 Gitmoji 的详细中文提交
```bash
gitmsgai -e -d
```

#### 自动化脚本结合
```bash
# 在 Shell 脚本或流水线中直接提交
git commit -m "$(gitmsgai -r)"
```

#### 设置 Git 快捷别名
```bash
git config --global alias.ai '!gitmsgai'
# 之后只需执行：
git add .
git ai
```

---

## 🧪 运行测试与静态分析

```bash
# 静态分析
dart analyze

# 自动化测试
dart test

# 代码格式化校验
dart format . --set-exit-if-changed
```

---

## 📄 架构设计

```text
bin/
  gitmsgai.dart            # CLI 入口与参数解析
lib/
  src/
    config/                # 配置管理器与分层配置（CLI > Local > Global）
    git/                   # Git CLI 进程调用与长差异保护
    prompt/                # Conventional Commits 提示词构造与响应清洗
    providers/             # DeepSeek, Gemini, OpenAI 驱动适配器
    ui/                    # 终端 ANSI 色彩、加载动画与交互提示
    commands/              # 生成与配置子命令实现
```
