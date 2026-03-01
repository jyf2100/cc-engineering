# 项目 2：代码审查 Bot

> 使用 TypeScript SDK 构建自动代码审查 Bot

---

## 场景说明

作为 GitHub App 运行，自动：
1. 监听 PR 事件
2. 审查代码变更
3. 发布审查评论

---

## 项目结构

```
02-review-bot/
├── README.md
├── src/
│   ├── bot/
│   │   ├── github_client.ts     # GitHub API 客户端
│   │   ├── reviewer.ts          # 审查逻辑
│   │   └── commenter.ts         # 评论发布
│   └── main.ts                  # 入口脚本
├── config/
│   └── review_rules.yaml        # 审查规则配置
├── package.json
└── tsconfig.json
```

---

## 核心代码

### src/bot/github_client.ts

```typescript
import { Octokit } from '@octokit/rest';

export interface PullRequestInfo {
  number: number;
  title: string;
  body: string;
  base: string;
  head: string;
  files: string[];
}

export class GitHubClient {
  private octokit: Octokit;
  private owner: string;
  private repo: string;

  constructor(token: string, owner: string, repo: string) {
    this.octokit = new Octokit({ auth: token });
    this.owner = owner;
    this.repo = repo;
  }

  async getPullRequest(prNumber: number): Promise<PullRequestInfo> {
    const { data: pr } = await this.octokit.pulls.get({
      owner: this.owner,
      repo: this.repo,
      pull_number: prNumber,
    });

    const { data: files } = await this.octokit.pulls.listFiles({
      owner: this.owner,
      repo: this.repo,
      pull_number: prNumber,
    });

    return {
      number: pr.number,
      title: pr.title,
      body: pr.body || '',
      base: pr.base.ref,
      head: pr.head.ref,
      files: files.map(f => f.filename),
    };
  }

  async getDiff(prNumber: number): Promise<string> {
    const { data } = await this.octokit.pulls.get({
      owner: this.owner,
      repo: this.repo,
      pull_number: prNumber,
      mediaType: { format: 'diff' },
    });
    return data as unknown as string;
  }

  async createReviewComment(
    prNumber: number,
    body: string
  ): Promise<void> {
    await this.octokit.issues.createComment({
      owner: this.owner,
      repo: this.repo,
      issue_number: prNumber,
      body,
    });
  }

  async createInlineComment(
    prNumber: number,
    commitId: string,
    path: string,
    line: number,
    body: string
  ): Promise<void> {
    await this.octokit.pulls.createReviewComment({
      owner: this.owner,
      repo: this.repo,
      pull_number: prNumber,
      commit_id: commitId,
      path,
      line,
      body,
    });
  }
}
```

### src/bot/reviewer.ts

```typescript
import { query, ClaudeCodeOptions } from '@anthropic-ai/claude-code';
import { GitHubClient, PullRequestInfo } from './github_client';

export interface ReviewResult {
  summary: string;
  issues: ReviewIssue[];
  suggestions: string[];
}

export interface ReviewIssue {
  file: string;
  line?: number;
  severity: 'high' | 'medium' | 'low';
  description: string;
  suggestion: string;
}

export class Reviewer {
  private githubClient: GitHubClient;

  constructor(githubClient: GitHubClient) {
    this.githubClient = githubClient;
  }

  async reviewPullRequest(prNumber: number): Promise<ReviewResult> {
    // 获取 PR 信息
    const pr = await this.githubClient.getPullRequest(prNumber);
    const diff = await this.githubClient.getDiff(prNumber);

    // 使用 Claude 审查
    const prompt = `
      Review this Pull Request for code quality and security issues.

      PR Title: ${pr.title}
      PR Description: ${pr.body}

      Changed Files: ${pr.files.join(', ')}

      Diff:
      \`\`\`diff
      ${diff}
      \`\`\`

      Provide a review in the following JSON format:
      {
        "summary": "Brief summary of the review",
        "issues": [
          {
            "file": "path/to/file",
            "line": 10,
            "severity": "high|medium|low",
            "description": "Issue description",
            "suggestion": "How to fix"
          }
        ],
        "suggestions": ["General suggestions"]
      }
    `;

    const result = await query(prompt, {
      allowedTools: ['Read', 'Grep', 'Glob'],
      outputFormat: 'json',
      maxTurns: 10,
      systemPrompt: `You are a code reviewer. Focus on:
        - Security vulnerabilities
        - Code quality issues
        - Performance concerns
        - Best practices

        Return your review as valid JSON only.`,
    });

    // 解析结果
    try {
      return JSON.parse(result.result) as ReviewResult;
    } catch {
      return {
        summary: result.result,
        issues: [],
        suggestions: [],
      };
    }
  }
}
```

### src/bot/commenter.ts

```typescript
import { GitHubClient } from './github_client';
import { ReviewResult, ReviewIssue } from './reviewer';

export class Commenter {
  private githubClient: GitHubClient;

  constructor(githubClient: GitHubClient) {
    this.githubClient = githubClient;
  }

  async postReview(prNumber: number, review: ReviewResult): Promise<void> {
    const body = this.formatReviewComment(review);
    await this.githubClient.createReviewComment(prNumber, body);
  }

  private formatReviewComment(review: ReviewResult): string {
    const sections: string[] = [];

    // 标题
    sections.push('## 🤖 Claude Code Review\n');

    // 摘要
    sections.push(`### Summary\n${review.summary}\n`);

    // 问题列表
    if (review.issues.length > 0) {
      sections.push('### Issues Found\n');
      for (const issue of review.issues) {
        const emoji = this.getSeverityEmoji(issue.severity);
        sections.push(`${emoji} **${issue.file}${issue.line ? `:${issue.line}` : ''}**`);
        sections.push(`- ${issue.description}`);
        sections.push(`- Suggestion: ${issue.suggestion}\n`);
      }
    } else {
      sections.push('### ✅ No Issues Found\n');
    }

    // 建议
    if (review.suggestions.length > 0) {
      sections.push('### Suggestions\n');
      for (const suggestion of review.suggestions) {
        sections.push(`- ${suggestion}`);
      }
    }

    sections.push('\n---\n*This review was automatically generated by Claude Code*');

    return sections.join('\n');
  }

  private getSeverityEmoji(severity: string): string {
    switch (severity) {
      case 'high': return '🔴';
      case 'medium': return '🟡';
      case 'low': return '🟢';
      default: return '⚪';
    }
  }
}
```

### src/main.ts

```typescript
#!/usr/bin/env node
import { GitHubClient } from './bot/github_client';
import { Reviewer } from './bot/reviewer';
import { Commenter } from './bot/commenter';

async function main() {
  // 从环境变量获取配置
  const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
  const REPO_OWNER = process.env.REPO_OWNER;
  const REPO_NAME = process.env.REPO_NAME;
  const PR_NUMBER = parseInt(process.env.PR_NUMBER || '0', 10);

  if (!GITHUB_TOKEN || !REPO_OWNER || !REPO_NAME || !PR_NUMBER) {
    console.error('Missing required environment variables');
    console.error('Required: GITHUB_TOKEN, REPO_OWNER, REPO_NAME, PR_NUMBER');
    process.exit(1);
  }

  // 初始化客户端
  const githubClient = new GitHubClient(GITHUB_TOKEN, REPO_OWNER, REPO_NAME);
  const reviewer = new Reviewer(githubClient);
  const commenter = new Commenter(githubClient);

  console.log(`Reviewing PR #${PR_NUMBER} in ${REPO_OWNER}/${REPO_NAME}`);

  // 执行审查
  const review = await reviewer.reviewPullRequest(PR_NUMBER);

  // 发布评论
  await commenter.postReview(PR_NUMBER, review);

  console.log('Review completed!');
  console.log(`Found ${review.issues.length} issues`);

  // 如果有高严重性问题，退出码为 1
  const hasHighSeverity = review.issues.some(i => i.severity === 'high');
  process.exit(hasHighSeverity ? 1 : 0);
}

main().catch(console.error);
```

---

## package.json

```json
{
  "name": "code-review-bot",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/main.js",
  "scripts": {
    "build": "tsc",
    "start": "node dist/main.js",
    "dev": "tsx src/main.ts"
  },
  "dependencies": {
    "@anthropic-ai/claude-code": "^0.1.0",
    "@octokit/rest": "^20.0.0",
    "yaml": "^2.3.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "tsx": "^4.0.0",
    "typescript": "^5.0.0"
  }
}
```

---

## 使用方法

```bash
# 安装依赖
npm install

# 构建
npm run build

# 运行
GITHUB_TOKEN=ghp_xxx \
REPO_OWNER=my-org \
REPO_NAME=my-repo \
PR_NUMBER=123 \
npm start
```

---

## 学习要点

1. **TypeScript SDK 使用**
   - `import { query } from '@anthropic-ai/claude-code'`
   - 使用 `outputFormat: 'json'` 解析结果

2. **GitHub API 集成**
   - 使用 `@octokit/rest` 库
   - 获取 PR diff、发布评论

3. **结构化输出**
   - 使用 JSON Schema 约束输出格式
   - 解析 JSON 结果

---

## 扩展

1. **内联评论**：在具体代码行发布评论
2. **规则配置**：从 YAML 文件加载审查规则
3. **增量审查**：只审查变更的代码
