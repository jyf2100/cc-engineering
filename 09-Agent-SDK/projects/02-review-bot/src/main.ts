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

  try {
    // 执行审查
    const review = await reviewer.reviewPullRequest(PR_NUMBER);

    // 发布评论
    await commenter.postReview(PR_NUMBER, review);

    console.log('Review completed!');
    console.log(`Found ${review.issues.length} issues`);

    // 如果有高严重性问题，退出码为 1
    const hasHighSeverity = review.issues.some(i => i.severity === 'high');
    process.exit(hasHighSeverity ? 1 : 0);
  } catch (error) {
    console.error('Review failed:', error);
    process.exit(1);
  }
}

main();
