# GitLab Skript Syntax Highlighting Patch

This package adds a first-pass [Rouge](https://rouge-ruby.github.io/) lexer and a [Linguist](https://github.com/github-linguist/linguist) language entry for Skript `.sk` files to a self-managed GitLab Docker image.

It is meant for **self-managed GitLab running in Docker**. It is not usable on GitLab.com.

## What this patches

The Dockerfile copies a custom `skript.rb` lexer into GitLab's bundled Rouge gem and adds a Rails initializer that loads it during GitLab boot. That handles syntax highlighting.

This targets GitLab's server-side highlighting path first: repository files, diffs, merge requests, commits, compare, and blame.

The Dockerfile also patches GitLab's bundled `github-linguist` gem so `.sk` files are detected as `Skript` for repository language statistics, including the colored language bar and percentages on the project overview.

It does **not** patch GitLab's frontend Highlight.js/Monaco bundles yet, so the Web IDE and some client-side-only views may not use this lexer.

## Files

```text
gitlab-skript-highlight/
├── Dockerfile
├── README.md
├── docker/
│   ├── skript.rb
│   ├── patch_linguist_skript.rb
│   └── zz_skript_rouge.rb
├── gitlab/
│   └── docker-compose.override.example.yml
├── project/
│   └── .gitattributes
├── scripts/
│   ├── build.sh
│   ├── install-into-running-container.sh
│   └── smoke-test.sh
└── test/
    └── example.sk
```

## Recommended install: custom image

This uses `docker buildx build --load` so the patched image is loaded into the local Docker image store after the build.

From this package directory:

```bash
# Optional: auto-detect the base image from a running container named "gitlab".
./scripts/build.sh
```

That builds:

```text
gitlab-skript:local
```

To use another buildx output mode, set `BUILDX_OUTPUT`, for example:

```bash
BUILDX_OUTPUT=--push \
GITLAB_IMAGE=gitlab/gitlab-ee:18.10.1-ee.0 \
OUTPUT_IMAGE=registry.example.com/gitlab-ee-skript:18.10.1 \
./scripts/build.sh
```

You can also explicitly choose the base image and output tag:

```bash
GITLAB_IMAGE=gitlab/gitlab-ee:18.10.1-ee.0 \
OUTPUT_IMAGE=gitlab-ee-skript:18.10.1 \
./scripts/build.sh
```

For GitLab CE:

```bash
GITLAB_IMAGE=gitlab/gitlab-ce:18.10.1-ce.0 \
OUTPUT_IMAGE=gitlab-ce-skript:18.10.1 \
./scripts/build.sh
```

Use the **exact image tag you currently run**. Do not rely on `latest` for production.

To see your current image:

```bash
docker inspect gitlab --format '{{.Config.Image}}'
```

## Deploy with Docker Compose

In your existing `docker-compose.yml`, change the GitLab service image:

```yaml
services:
  gitlab:
    image: gitlab-skript:local
```

Do not remove your existing persistent volumes, environment, ports, hostname, or `shm_size` settings.

Then recreate GitLab:

```bash
docker compose up -d
```

## Deploy with `docker run`

Use the same `docker run` command you already use, but replace the image at the end with your patched image tag, for example:

```bash
gitlab-skript:local
```

Keep your existing volume mounts for:

```text
/etc/gitlab
/var/log/gitlab
/var/opt/gitlab
```

## Repository setup

Add this to each Skript repository as `.gitattributes`:

```gitattributes
*.sk gitlab-language=skript linguist-language=Skript
```

A ready-made copy is included at:

```text
project/.gitattributes
```

In most cases, `.sk` should be detected automatically after this patch:

- Rouge declares `filenames "*.sk"` for highlighting.
- Linguist registers `.sk` as `Skript` for repository language statistics.

The `.gitattributes` line makes both GitLab-specific highlighting and Linguist language statistics explicit.

## Smoke test

After the patched container is running:

```bash
./scripts/smoke-test.sh
```

Or specify a different container name:

```bash
CONTAINER_NAME=my-gitlab ./scripts/smoke-test.sh
```

Expected output should include:

```text
Found lexer: Skript
Found Linguist language: Skript
```

## Quick temporary install into a running container

This is only for fast testing. It is **not persistent** across container replacement or image upgrades.

```bash
./scripts/install-into-running-container.sh
```

Then run:

```bash
./scripts/smoke-test.sh
```

For production, build a custom image instead.

## Upgrading GitLab later

When you upgrade GitLab:

1. Pull the new upstream GitLab image.
2. Rebuild this patch using the new upstream image tag.
3. Deploy the rebuilt patched image.
4. Run `./scripts/smoke-test.sh`.

Example:

```bash
GITLAB_IMAGE=gitlab/gitlab-ee:<new-version>-ee.0 \
OUTPUT_IMAGE=gitlab-ee-skript:<new-version> \
./scripts/build.sh
```

## Lexer scope

This first-pass lexer highlights:

- comments
- quoted strings
- Skript variables like `{spawn}`, `{_local}`, and `{data::%uuid of player%}`
- command and function declarations
- common sections such as `trigger:`, `options:`, and `variables:`
- common events like `on join:` and `on death:`
- control flow such as `if`, `else`, `loop`, `return`, `stop`, and `cancel`
- common effects such as `send`, `teleport`, `give`, `set`, `delete`, and `broadcast`
- Minecraft legacy color codes such as `&a` and `§c`
- simple MiniMessage-ish tags such as `<green>` and `<#ff00aa>`

It is intentionally conservative. It will not perfectly parse every Skript addon syntax yet.

## Troubleshooting

### `Skript lexer did not register` during build

The base GitLab image may have changed how Rouge is packaged. Run:

```bash
docker run --rm -it <your-gitlab-image> bash
/opt/gitlab/embedded/bin/ruby -e 'require "rubygems"; puts Gem::Specification.find_by_name("rouge").full_gem_path'
```

Then check whether the Rouge lexer directory exists under:

```text
lib/rouge/lexers
```

### Files still do not highlight

Make sure the repo has:

```gitattributes
*.sk gitlab-language=skript linguist-language=Skript
```

Then commit and push the file.

Also try clearing Rails caches or restarting GitLab services:

```bash
docker exec -it gitlab gitlab-ctl restart puma sidekiq
```

### Language percentages still do not show Skript

Make sure the repo has:

```gitattributes
*.sk gitlab-language=skript linguist-language=Skript
```

Then commit and push the file. GitLab may cache repository language statistics, so give Sidekiq time to recalculate or restart GitLab services after installing the patch.

### Web IDE still has no Skript highlighting

Expected. This package only patches Rouge. Web IDE/Monaco support would require a separate frontend language grammar.
