# claude-ecs-task

Claude Code CLI をコンテナ内で非インタラクティブに実行するサンプルです。  
EFS（本番）をローカルディレクトリで模倣し、マウントしたファイルを Claude に解析させます。

---

## ECR自動プッシュ 設定TODO（上から順に実施）

GitLab に push すると CI/CD が動き、ECR へ自動でイメージがプッシュされる状態にします。

### ✅ 完了済み

- [x] Dockerfile 作成（`node:20-slim` + Claude Code CLI、非rootユーザーで実行）
- [x] `.gitlab-ci.yml` 作成（`main` ブランチ push → docker build → ECR push）
- [x] ECS 作成済み

---

### Step 1｜ECR リポジトリを作成する（AWSコンソール）

1. AWS マネジメントコンソール → **ECR** を開く
2. 「リポジトリを作成」をクリック
3. リポジトリ名: `claude-ecs-task`（任意）
4. 作成後、リポジトリの URI をメモしておく  
   例: `123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/claude-ecs-task`

---

### Step 2｜GitLab Runner を privileged モードで動かす（ランナーサーバー側）

`.gitlab-ci.yml` は Docker-in-Docker（dind）を使っているため、Runner の `privileged = true` が必要です。

Runner の設定ファイル（通常 `/etc/gitlab-runner/config.toml`）を確認・編集します。

```toml
[[runners]]
  ...
  [runners.docker]
    privileged = true   # ← この行を追加 or true になっていることを確認
    ...
```

編集後、Runner を再起動します。

```bash
sudo gitlab-runner restart
```

---

### Step 3｜GitLab の CI/CD 変数を登録する

AWS の認証情報は GitLab Runner サーバーの IAM ロールから自動取得されるため、アクセスキーの登録は不要です。

GitLab リポジトリの **Settings > CI/CD > Variables** に以下の2つだけ追加します。

| 変数名 | 値 | 備考 |
|---|---|---|
| `AWS_DEFAULT_REGION` | 例: `ap-northeast-1` | ECR のリージョン |
| `ECR_REGISTRY` | 例: `123456789012.dkr.ecr.ap-northeast-1.amazonaws.com` | Step1 でメモしたURIのリポジトリ名より前の部分 |
| `ECR_REPOSITORY` | 例: `claude-ecs-task` | Step1 で作ったリポジトリ名 |

---

### Step 4｜このリポジトリを GitLab に push して動作確認

```bash
git remote add gitlab <自社GitLabのリポジトリURL>
git push gitlab main
```

GitLab の **CI/CD > Pipelines** を開き、パイプラインが green になれば完了です。  
ECR コンソールでイメージが登録されていることも確認してください。

---

## ローカルでの動作確認方法（Docker単体）

### 1. APIキーファイルを作成する

`env.txt`（`.gitignore` 済み）をルートに作成し、Anthropic API キーを記入します。

```bash
echo "ANTHROPIC_API_KEY=sk-ant-xxxxxx" > env.txt
```

APIキーは https://console.anthropic.com で発行できます。

### 2. コンテナをビルドする

```bash
docker build -t claude-ecs-task .
```

### 3. 実行する

```bash
docker run --rm \
  --env-file env.txt \
  -v $(pwd)/efs-mock:/mnt/efs \
  claude-ecs-task
```

`efs-mock/src/` 内のファイルを Claude がレビューし、結果を標準出力に表示して終了します。

## 解析対象ファイルを変えるには

`efs-mock/src/` に解析したいファイルを置いてから実行してください。  
プロンプトを変えたい場合は `Dockerfile` の `CMD` を編集します。

```dockerfile
CMD ["claude", "-p", "任意のプロンプト", "--dangerously-skip-permissions"]
```
