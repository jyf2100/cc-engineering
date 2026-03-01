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
${diff.substring(0, 10000)} // 限制长度
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
