# create-github-repo.sh

GitHub リポジトリを作成し、ブランチ保護・CODEOWNERS・各種機能を一括設定するスクリプトです。

## 機能

実行すると以下を自動で行います：

1. GitHub CLI でログイン (`gh auth login`)
2. リポジトリを作成（公開/非公開・説明文を設定可）
3. `CODEOWNERS` ファイルを追加してプッシュ（全ファイルの変更にオーナー承認を要求）
4. Discussions・Projects を有効化
5. `main` ブランチに保護ルールセットを作成
   - ブランチ削除の禁止
   - 強制プッシュの禁止
   - PR マージ前に承認者 1 名必須
   - コードオーナーのレビュー必須
   - プッシュ時に古いレビューを無効化
6. GitHub CLI からログアウト

## 前提条件

- [GitHub CLI (`gh`)](https://cli.github.com/) がインストール済みであること
- `git` がインストール済みであること

## 使い方

```bash
# 対話モード（引数なし）
./create-github-repo.sh

# 引数を指定して実行
./create-github-repo.sh <REPO_NAME> [DESCRIPTION] [public|private]
```

### 引数

| 引数 | 説明 | デフォルト |
|------|------|-----------|
| `REPO_NAME` | リポジトリ名 | 対話入力 |
| `DESCRIPTION` | リポジトリの説明（省略可） | 対話入力 |
| `public\|private` | 公開設定 | 対話入力（デフォルト: `private`） |

### 実行例

```bash
# リポジトリ名・説明・公開設定をすべて指定
./create-github-repo.sh my-repo "My description" private

# リポジトリ名のみ指定（他は対話入力）
./create-github-repo.sh my-repo

# すべて対話入力
./create-github-repo.sh
```

## ブランチ保護ルールの詳細

`main` ブランチに以下のルールセット（`Protect main`）が作成されます：

| ルール | 設定 |
|--------|------|
| ブランチ削除 | 禁止 |
| 強制プッシュ | 禁止 |
| 必要承認者数 | 1 名 |
| コードオーナーのレビュー | 必須 |
| プッシュ時に古いレビューを無効化 | 有効 |

## 注意事項

- スクリプト終了時に一時ディレクトリは自動削除されます
- スクリプト完了後、`gh auth logout` が自動実行されます
- リポジトリ名は空にできません
