# Wrangler and Deployment Guide

Wrangler is the official CLI for developing, testing, and deploying Cloudflare Workers.

## Installation

```bash
# NPM (global)
npm install -g wrangler

# NPM (project-local)
npm install --save-dev wrangler

# Verify installation
wrangler --version
```

## Authentication

```bash
# Login via browser (recommended)
wrangler login

# Or use API token
export CLOUDFLARE_API_TOKEN=your-token
```

## Essential Commands

### Project Initialization

```bash
# Initialize new project
wrangler init my-worker

# With template
wrangler init my-worker --template cloudflare/workers-sdk

# Interactive setup with C3
npm create cloudflare@latest my-worker
```

### Development

```bash
# Start local dev server
wrangler dev

# Custom port
wrangler dev --port 8080

# With remote resources (bindings)
wrangler dev --remote

# Local mode (no network requests to Cloudflare)
wrangler dev --local

# Test worker (experimental)
wrangler dev --test-scheduled
```

### Deployment

```bash
# Deploy to production
wrangler deploy

# Deploy to specific environment
wrangler deploy --env staging
wrangler deploy --env production

# Dry run (validate without deploying)
wrangler deploy --dry-run

# Deploy specific file
wrangler deploy src/index.ts

# Deploy with message
wrangler deploy --message "Fix authentication bug"
```

### Version Management

```bash
# List versions
wrangler versions list

# View specific version
wrangler versions view <version-id>

# Deploy specific version
wrangler versions deploy <version-id>

# Rollback to previous version
wrangler rollback

# Gradual rollout
wrangler versions deploy <version-id> --percentage 10
```

## Configuration (wrangler.toml)

### Basic Structure

```toml
#:schema node_modules/wrangler/config-schema.json
name = "my-worker"
main = "src/index.ts"
compatibility_date = "2025-01-01"

# Account/Zone (usually auto-detected)
account_id = "your-account-id"

# Workers.dev subdomain
workers_dev = true

# Or custom domain
routes = [
  { pattern = "example.com/*", zone_name = "example.com" },
  { pattern = "api.example.com/*", zone_name = "example.com" }
]
```

### Environment Variables

```toml
# Non-sensitive variables
[vars]
ENVIRONMENT = "production"
API_ENDPOINT = "https://api.example.com"
FEATURE_FLAGS = '{"newUI": true}'

# Per-environment
[env.staging.vars]
ENVIRONMENT = "staging"
API_ENDPOINT = "https://staging-api.example.com"
```

### Secrets

```bash
# Set secret via CLI (not in wrangler.toml!)
wrangler secret put API_KEY
# Enter value when prompted

# List secrets
wrangler secret list

# Delete secret
wrangler secret delete API_KEY

# Bulk import from .env
wrangler secret bulk .env.production
```

### Bindings Configuration

**KV:**
```toml
[[kv_namespaces]]
binding = "MY_KV"
id = "your-namespace-id"
preview_id = "preview-namespace-id"
```

**D1:**
```toml
[[d1_databases]]
binding = "DB"
database_name = "production-db"
database_id = "xxxx-xxxx-xxxx"
```

**R2:**
```toml
[[r2_buckets]]
binding = "MY_BUCKET"
bucket_name = "my-bucket"
preview_bucket_name = "my-bucket-preview"
```

**Durable Objects:**
```toml
[[durable_objects.bindings]]
name = "COUNTER"
class_name = "Counter"
script_name = "my-worker"

[[migrations]]
tag = "v1"
new_classes = ["Counter"]
```

**Queues:**
```toml
[[queues.producers]]
binding = "MY_QUEUE"
queue = "my-queue"

[[queues.consumers]]
queue = "my-queue"
max_batch_size = 10
max_batch_timeout = 30
max_retries = 3
dead_letter_queue = "my-dlq"
```

**Service Bindings:**
```toml
[[services]]
binding = "AUTH_SERVICE"
service = "auth-worker"
environment = "production"
```

**Workers AI:**
```toml
[ai]
binding = "AI"
```

### Cron Triggers

```toml
[triggers]
crons = [
  "0 0 * * *",     # Daily at midnight
  "*/15 * * * *",  # Every 15 minutes
  "0 9 * * 1-5"    # Weekdays at 9 AM
]
```

### Static Assets

```toml
[assets]
directory = "./public"
binding = "ASSETS"

# HTML handling
html_handling = "auto-trailing-slash"  # or "drop-trailing-slash", "none"

# Not found handling
not_found_handling = "single-page-application"  # or "404-page", "none"
```

### Compatibility

```toml
# Compatibility date (required)
compatibility_date = "2025-01-01"

# Compatibility flags
compatibility_flags = [
  "nodejs_compat",
  "transformstream_enable_standard_constructor"
]
```

### Custom Builds

```toml
[build]
command = "npm run build"
watch_dirs = ["src", "public"]

[build.upload]
format = "modules"
dir = "dist"
main = "./index.js"
```

## Multi-Environment Setup

### Environment Structure

```toml
# Global settings
name = "my-worker"
main = "src/index.ts"
compatibility_date = "2025-01-01"

# Default/production
[vars]
ENVIRONMENT = "production"

[[kv_namespaces]]
binding = "CACHE"
id = "prod-kv-id"

# Staging environment
[env.staging]
name = "my-worker-staging"
vars = { ENVIRONMENT = "staging" }

[[env.staging.kv_namespaces]]
binding = "CACHE"
id = "staging-kv-id"

# Development environment
[env.dev]
name = "my-worker-dev"
vars = { ENVIRONMENT = "development" }

[[env.dev.kv_namespaces]]
binding = "CACHE"
id = "dev-kv-id"
```

### Deploying Environments

```bash
# Deploy to production (default)
wrangler deploy

# Deploy to staging
wrangler deploy --env staging

# Deploy to dev
wrangler deploy --env dev
```

## CI/CD Integration

### GitHub Actions

**.github/workflows/deploy.yml:**

```yaml
name: Deploy Worker

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    name: Deploy
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Deploy to Cloudflare Workers
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

**Multi-environment:**

```yaml
name: Deploy Workers

on:
  push:
    branches: [main, staging]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Deploy to staging
        if: github.ref == 'refs/heads/staging'
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          environment: 'staging'

      - name: Deploy to production
        if: github.ref == 'refs/heads/main'
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

### GitLab CI/CD

**.gitlab-ci.yml:**

```yaml
stages:
  - deploy

deploy_production:
  stage: deploy
  image: node:18
  script:
    - npm ci
    - npx wrangler deploy
  only:
    - main
  variables:
    CLOUDFLARE_API_TOKEN: $CLOUDFLARE_API_TOKEN
    CLOUDFLARE_ACCOUNT_ID: $CLOUDFLARE_ACCOUNT_ID
```

## Workers Builds (Git Integration)

Enable automatic deployments on git push via the dashboard.

**Setup:**
1. Connect your GitHub/GitLab repository
2. Configure build settings
3. Set environment variables
4. Enable branch deployments

**Benefits:**
- Automatic builds on push
- Preview deployments for PRs
- Build caching
- Deployment history

## Versioning & Gradual Deployments

### Versions

Workers automatically create versions on each deployment.

```bash
# List versions
wrangler versions list

# View specific version
wrangler versions view <version-id>

# Deploy specific version
wrangler versions deploy <version-id>
```

### Gradual Rollouts

Incrementally deploy new versions to reduce risk.

**Via Wrangler:**

```bash
# Deploy to 10% of traffic
wrangler versions deploy <version-id> --percentage 10

# Increase to 50%
wrangler versions deploy <version-id> --percentage 50

# Full rollout
wrangler versions deploy <version-id> --percentage 100
```

**Via Configuration:**

```toml
[[workflows.deployments]]
version_id = "new-version-id"
percentage = 10

[[workflows.deployments]]
version_id = "old-version-id"
percentage = 90
```

### Rollback

```bash
# Rollback to previous version
wrangler rollback

# List rollback history
wrangler rollback --list

# Rollback to specific version
wrangler versions deploy <previous-version-id>
```

## Resource Management

### KV Namespaces

```bash
# Create namespace
wrangler kv:namespace create "MY_KV"
wrangler kv:namespace create "MY_KV" --preview

# List namespaces
wrangler kv:namespace list

# Delete namespace
wrangler kv:namespace delete --namespace-id=<id>

# Put key-value
wrangler kv:key put "key" "value" --namespace-id=<id>

# Get value
wrangler kv:key get "key" --namespace-id=<id>

# List keys
wrangler kv:key list --namespace-id=<id>

# Delete key
wrangler kv:key delete "key" --namespace-id=<id>

# Bulk operations
wrangler kv:bulk put data.json --namespace-id=<id>
wrangler kv:bulk delete keys.json --namespace-id=<id>
```

### D1 Databases

```bash
# Create database
wrangler d1 create my-database

# List databases
wrangler d1 list

# Execute SQL
wrangler d1 execute my-database --command="SELECT * FROM users"

# Execute from file
wrangler d1 execute my-database --file=schema.sql

# Migrations
wrangler d1 migrations create my-database "add-users-table"
wrangler d1 migrations apply my-database
wrangler d1 migrations list my-database

# Export database
wrangler d1 export my-database --output=backup.sql

# Time Travel (restore)
wrangler d1 time-travel restore my-database --timestamp=<timestamp>
```

### R2 Buckets

```bash
# Create bucket
wrangler r2 bucket create my-bucket

# List buckets
wrangler r2 bucket list

# Delete bucket
wrangler r2 bucket delete my-bucket

# Put object
wrangler r2 object put my-bucket/file.txt --file=./file.txt

# Get object
wrangler r2 object get my-bucket/file.txt --file=./downloaded.txt

# List objects
wrangler r2 object list my-bucket

# Delete object
wrangler r2 object delete my-bucket/file.txt
```

### Queues

```bash
# Create queue
wrangler queues create my-queue

# List queues
wrangler queues list

# Delete queue
wrangler queues delete my-queue

# Send test message
wrangler queues send my-queue '{"test": "message"}'
```

## Debugging & Troubleshooting

### Tail Logs (Real-time)

```bash
# Tail logs from production
wrangler tail

# Tail specific environment
wrangler tail --env staging

# Filter by status
wrangler tail --status error

# Filter by method
wrangler tail --method POST

# Pretty print
wrangler tail --format pretty
```

### Deployment Issues

**Version conflicts:**
```bash
# Force overwrite
wrangler deploy --force
```

**Bundle size issues:**
```bash
# Check bundle size
wrangler deploy --dry-run --outdir=dist

# Optimize
npm run build -- --minify
```

**Authentication issues:**
```bash
# Re-login
wrangler login

# Use API token
export CLOUDFLARE_API_TOKEN=your-token
```

## Best Practices

### Configuration Management

1. **Use environments** for staging/production
2. **Store secrets in Wrangler**, not in config files
3. **Use compatibility dates** to lock runtime behavior
4. **Version control** your wrangler.toml

### Deployment Strategy

1. **Test locally** with `wrangler dev`
2. **Deploy to staging** first
3. **Use gradual rollouts** for production
4. **Monitor logs** during deployment
5. **Keep previous versions** for quick rollback

### CI/CD Best Practices

1. **Separate staging and production** workflows
2. **Use deployment keys** with minimal permissions
3. **Run tests** before deployment
4. **Tag releases** in git
5. **Notify team** on deployments

### Performance Optimization

1. **Minimize bundle size** - Tree-shake unused code
2. **Use custom builds** for complex projects
3. **Enable build caching** in CI/CD
4. **Optimize dependencies** - Use smaller packages

## Advanced Features

### Custom Domains

```toml
routes = [
  { pattern = "api.example.com/*", zone_name = "example.com", custom_domain = true }
]
```

```bash
# Add custom domain via CLI
wrangler domains add api.example.com
```

### Workers for Platforms

Deploy user-provided Workers on your infrastructure.

```toml
[[dispatch_namespaces]]
binding = "DISPATCHER"
namespace = "my-namespace"
outbound = { service = "my-worker" }
```

### Smart Placement

Automatically place Workers near data sources.

```toml
[placement]
mode = "smart"
```

## Additional Resources

- **Wrangler Docs**: https://developers.cloudflare.com/workers/wrangler/
- **Configuration**: https://developers.cloudflare.com/workers/wrangler/configuration/
- **Commands**: https://developers.cloudflare.com/workers/wrangler/commands/
- **CI/CD**: https://developers.cloudflare.com/workers/ci-cd/
- **GitHub Actions**: https://github.com/cloudflare/wrangler-action
