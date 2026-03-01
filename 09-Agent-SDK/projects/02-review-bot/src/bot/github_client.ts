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
    const response = await this.octokit.pulls.get({
      owner: this.owner,
      repo: this.repo,
      pull_number: prNumber,
      mediaType: { format: 'diff' },
    });
    return response.data as unknown as string;
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

  async getFileContent(path: string, ref: string): Promise<string> {
    const { data } = await this.octokit.repos.getContent({
      owner: this.owner,
      repo: this.repo,
      path,
      ref,
    });

    if ('content' in data) {
      return Buffer.from(data.content, 'base64').toString('utf-8');
    }
    return '';
  }
}
