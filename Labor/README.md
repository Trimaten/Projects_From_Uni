# Wave - Installation & Requirements

---
### Prerequisites

Make sure the following software is installed on your system:

* [Docker](https://docs.docker.com/get-docker/)
* [Docker Compose](https://docs.docker.com/compose/install/)
* (Optional for developers) [Git](https://git-scm.com/) and an editor like [VS Code](https://code.visualstudio.com/)

---
### Installation Guide for Administrators

**Wave** is a Ruby on Rails application that uses **PostgreSQL** as its database and **Devise** for authentication. The UI is built with **Tailwind CSS**.

The entire development environment is containerized using Docker Compose.

---
### 🔧 Installation Steps

1.  **Clone the project:**
    ```bash
    git clone <REPO-URL> wave
    cd wave
    ```
2.  **Start the Docker containers:**
    ```bash
    docker-compose up --build -d
    ```
    (`-d` for detached mode)

On first launch, the following will happen automatically:

* Required Ruby gems are installed (`bundle install`)
* Database migrations are applied (`rails db:migrate`)
* Assets are precompiled (`rails assets:precompile`)
* Tailwind CSS starts in watch mode (`rails tailwindcss:watch`)
* The Rails server starts (`rails server`)

The application will be available at:

[http://localhost:3001](http://localhost:3001)

---
### 📂 Project Structure (Quick Overview)

* `webapp`: Contains the Rails application code
* `database`: PostgreSQL database with custom credentials
* `volumes`: Persistent database storage (`db-data`)

---
### 🔐 Database Access

* **Host:** `localhost`
* **Port:** `5432`
* **User:** `wave`
* **Password:** `5g9wg9qT3gvFacMezZcQs2W2zEHjrLJg`
* **Database name:** `wave`

You can use tools like **pgAdmin** for direct access to the database if needed.

---
### 🧪 Healthcheck & Dependencies

The application automatically waits for the database to be ready before starting. This is handled via `depends_on` and a health check defined in the respective `docker-compose.yml` files for each environment.
---

### ⚙️ Application Configuration

This section covers important configurations for our Wave application, including host whitelisting and mailer settings.

#### Host Whitelisting (`config.hosts`)

For security reasons, especially in production, Rails applications require you to explicitly whitelist allowed hosts. This prevents DNS rebinding attacks. You'll find these settings in `config/environments/development.rb` and `config/environments/production.rb`.

**Development (`config/environments/development.rb`):**

```ruby
Rails.application.configure do
  # ... other development settings ...

  config.hosts << "waveapp.software"
  config.assets.debug = true
end
```

**Production (`config/environments/production.rb`):**

```ruby
Rails.application.configure do
  # ... other production settings ...

  # Enable DNS rebinding protection and other `Host` header attacks.
  config.hosts << "waveapp.software"
end
```

#### Mailer Configuration (SMTP)

Wave uses Action Mailer for sending emails. SMTP settings are configured differently for development and production environments.

**Development (`config/environments/development.rb`):**

```ruby
Rails.application.configure do
  # ... other development settings ...

  config.action_mailer.raise_delivery_errors = true # Good for development to see errors
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              'smtp.gmail.com',
    port:                 587,
    domain:               'gmail.com',
    user_name:            'softwarewaveapp@gmail.com',
    password:             'your_fake_dev_smtp_password', # Replaced with fake password
    authentication:       'plain',
    enable_starttls_auto: true,
    open_timeout:         5, # Optional: Add timeouts for robustness
    read_timeout:         5
  }

  config.action_mailer.default_url_options = { host: 'localhost', port: 3001 }

  # ... rest of development settings ...
end
```

**Production (`config/environments/production.rb`):**

```ruby
Rails.application.configure do
  # ... other production settings ...

  config.action_mailer.raise_delivery_errors = false # Typically false in production to prevent app crash
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              'smtp.gmail.com',
    port:                 587,
    domain:               'waveapp.software',
    user_name:            'softwarewaveapp@gmail.com',
    password:             'your_fake_prod_smtp_password', # Replaced with fake password
    authentication:       'plain',
    enable_starttls_auto: true,
    open_timeout:         5,
    read_timeout:         5
  }

  config.action_mailer.default_url_options = { host: 'waveapp.software', protocol: 'https' }

  # ... rest of production settings ...
end
```

-----

### 📊 Database Configuration (`config/database.yml`)

The `config/database.yml` file defines database connections for different Rails environments and services like Active Job.

```yaml
development:
  adapter: postgresql
  url: <%= ENV["DATABASE_URL"] %>
  database: wave
  username: wave
  password: 5g9wg9qT3gvFacMezZcQs2W2zEHjrLJg
  encoding: unicode

test:
  adapter: postgresql
  url: <%= ENV["DATABASE_URL"] %>
  database: wave
  username: wave
  password: 5g9wg9qT3gvFacMezZcQs2W2zEHjrLJg
  encoding: unicode

production:
  adapter: postgresql
  url: <%= ENV["DATABASE_URL"] %>
  database: wave_production
  username: wave_production
  password: <%= ENV["WAVE_PRODUCTION_DATABASE_PASSWORD"] %>
  encoding: unicode

cable:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  url: <%= ENV["DATABASE_URL"] %>

queue:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  url: <%= ENV["DATABASE_URL"] %>

cache:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  url: <%= ENV["CACHE_DATABASE_URL"] %>
```

-----

### 🐳 Docker Compose Environments

Wave uses three different Docker Compose files to manage its environments:

  * `docker-compose.yml`: For local development.
  * `docker-compose.test.yml`: Used specifically for running tests in the CI/CD pipeline.
  * `docker-compose.production.yml`: For deploying the application in a production-like containerized environment.

#### Development Environment (`docker-compose.yml`)

This is the default file used when you run `docker-compose up --build` and is designed for local development. Its content is implied by the "Installation Steps" section above.

#### Test Environment (`docker-compose.test.yml`)

This file is configured to run your application tests within an isolated Docker environment. It uses a separate database instance for testing.

```yaml
services:
  testapp:
    image: placeholder # This image will be replaced by the CI pipeline with the built image
    ports:
      - "3002:3000"
    depends_on:
      databaseT:
        condition: service_healthy  # Check if database is running and accepting connections
    environment:
      - RAILS_ENV=test # Important for test database connection
      - DATABASE_URL=postgres://wave:5g9wg9qT3gvFacMezZcQs2W2zEHjrLJg@databaseT:5432/wave

  databaseT:
    image: postgres:17.4
    ports:
      - "5433:5432"
    environment:
      TZ: Europe/Berlin
      POSTGRES_USER: wave
      POSTGRES_PASSWORD: 5g9wg9qT3gvFacMezZcQs2W2zEHjrLJg
      POSTGRES_DB: wave
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --auth=md5"
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "wave"] # Check if db is running and allows connections with user wave
      interval: 5s
      retries: 5
      start_period: 10s
      timeout: 5s
    volumes:
      - db-data-t:/var/lib/postgresql/data

volumes:
  db-data-t:
```

#### Production Environment (`docker-compose.production.yml`)

This file is tailored for a production deployment, ensuring the Rails application runs in `production` mode and connects to its dedicated production database.

```yaml
services:
  webapp:
    build: .
    volumes:
      - ./:/app
    ports:
      - "3001:3000"
    depends_on:
      database:
        condition: service_healthy  # Check if database is running and accepting connections
    environment:
      - RAILS_ENV=production    # Important to run in production mode
      - DATABASE_URL=postgres://wave_production:5g9wg9qT3gvFacMezZcQs2W2zEHjrLJg@database:5432/wave_production
    command: bash -c "rm -f tmp/pids/server.pid && bundle install && bundle exec rails db:migrate && rails assets:precompile & rails tailwindcss:watch && bundle exec rails server -b 0.0.0.0"

  database:
    image: postgres:17.4
    ports:
      - "5432:5432"
    environment:
      TZ: Europe/Berlin
      POSTGRES_USER: wave_production
      POSTGRES_PASSWORD: 5g9wg9qT3gvFacMezZcQs2W2zEHjrLJg
      POSTGRES_DB: wave_production
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --auth=md5"
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "wave_production"] # Check if db is running and allows connections with user wave
      interval: 5s
      retries: 5
      start_period: 10s
      timeout: 5s
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

-----

### 🚀 CI/CD Setup with GitLab

Wave uses GitLab CI/CD to automate the build, test, and deployment process.

#### GitLab Runner Setup

To enable CI/CD, you need to set up a GitLab Runner. You can run the runner in a Docker container using the following `docker-compose.yml` configuration (separate from the application's Docker Compose files):

```yaml
services:
  gitlab-runner:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner
    restart: always
    volumes:
      - ./config:/etc/gitlab-runner # Mount a volume for runner configuration
      - /var/run/docker.sock:/var/run/docker.sock # Allow runner to interact with Docker daemon
      - /home/kot/labor/gitlab-runner/ssh:/home/gitlab-runner/.ssh:ro # Mount SSH keys read-only
```

You'll need to register this runner with your GitLab project. The SSH volume (`/home/gitlab-runner/.ssh:ro`) is crucial for deployment steps that require SSH access to your production server.

#### GitLab CI/CD Pipeline (`.gitlab-ci.yml`)

The `.gitlab-ci.yml` file defines your CI/CD pipeline, including stages for building, testing, deploying, and notifying.

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
    - if: $CI_PIPELINE_SOURCE == "merge_request" && $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == "main"

stages:
  - build
  - test
  - deploy
  - notify

variables:
  IMAGE_NAME: "registry.it.hs-heilbronn.de/it/courses/seb/lab/ss25/group-03:$CI_COMMIT_REF_SLUG"
  DOCKER_REGISTRY: $CI_REGISTRY
  DOCKER_IMAGE_NAME: $CI_REGISTRY_IMAGE/$CI_COMMIT_BRANCH # Image name based on branch
  LATEST_DOCKER_IMAGE_NAME: $CI_REGISTRY_IMAGE/latest
  DISCORD_WEBHOOK_URL: "[https://discord.com/api/webhooks/1364147816859045979/CANX-n1dIA0SKyt0Fsnfb3DMXtBPaV-NxvOW2YSy4ELdF0d1lEof04BBBEw8vHz3bb](https://discord.com/api/webhooks/1364147816859045979/CANX-n1dIA0SKyt0Fsnfb3DMXtBPaV-NxvOW2YSy4ELdF0d1lEof04BBBEw8vHz3bb)" # Make sure this is set as a secret variable
  GITLAB_PROJECT_URL: "[https://git.it.hs-heilbronn.de/it/courses/seb/lab/ss25/group-03](https://git.it.hs-heilbronn.de/it/courses/seb/lab/ss25/group-03)" # Your project URL

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
  script:
    - echo "Building Docker image for branch $CI_COMMIT_BRANCH..."
    - docker build -t $IMAGE_NAME .
    - docker push $IMAGE_NAME

test:
  stage: test
  image: docker:latest # Keeping it minimal for testing core logic
  services:
    - docker:dind
  dependencies:
    - build
  before_script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
  script:
    - echo "Pulling image:" $IMAGE_NAME
    - docker pull $IMAGE_NAME
    - sed -i "s|placeholder|$IMAGE_NAME|g" docker-compose.test.yml
    - docker-compose -f docker-compose.test.yml down --remove-orphans # Clean up any previous test runs
    - docker-compose -f docker-compose.test.yml up -d
    - docker-compose -f docker-compose.test.yml exec testapp bin/rails db:migrate:reset
    - docker-compose -f docker-compose.test.yml exec testapp bin/rails test test/
    - docker-compose -f docker-compose.test.yml down
    - echo "Test environment stopped."
  artifacts:
    expire_in: 1 hour

deploy:
  stage: deploy
  image: docker:latest
  services:
    - docker:dind
  dependencies:
    - test
  before_script:
    - 'command -v ssh-agent >/dev/null || ( apt-get update -y && apt-get install openssh-client -y )'
    - 'command -v base64 >/dev/null || ( apt-get update -y && apt-get install coreutils -y )'
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | base64 -d | ssh-add - # Decode and add SSH private key
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
    - cp "$SSH_KNOWN_HOSTS" ~/.ssh/known_hosts # Copy known hosts for SSH
    - chmod 644 ~/.ssh/known_hosts
  rules:
    - if: $CI_COMMIT_BRANCH == "main" || $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
  script:
    - echo "Deployment script executed."
    - ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@193.196.55.154 "cd /home/ubuntu/group-03 && ./deploy.sh"
  environment:
    name: production

notify_test_success:
  stage: notify
  image: ubuntu:latest
  dependencies:
    - test
  rules:
    - when: on_success
  script:
    - apt-get update -yq
    - apt-get install -yq curl
    - DISCORD_MESSAGE=""
    - BRANCH_NAME="$CI_COMMIT_BRANCH"
    - PIPELINE_ID="$CI_PIPELINE_ID"
    - PIPELINE_URL="$GITLAB_PROJECT_URL/-/pipelines/$CI_PIPELINE_ID"
    - |
      DISCORD_MESSAGE="✅ Tests in branch '$BRANCH_NAME' (Pipeline #$PIPELINE_ID) were successful! Pipeline URL: $PIPELINE_URL"
      curl -X POST -H "Content-Type: application/json" -d "{\"content\":\"$DISCORD_MESSAGE\"}" "$DISCORD_WEBHOOK_URL"

notify_test_failure:
  stage: notify
  image: ubuntu:latest
  dependencies:
    - test
  rules:
    - when: on_failure
  script:
    - apt-get update -yq
    - apt-get install -yq curl
    - pwd
    - DISCORD_MESSAGE=""
    - BRANCH_NAME="$CI_COMMIT_BRANCH"
    - PIPELINE_ID="$CI_PIPELINE_ID"
    - PIPELINE_URL="$GITLAB_PROJECT_URL/-/pipelines/$CI_PIPELINE_ID"
    - CI_JOB_URL_TEST=$(echo "$CI_PROJECT_URL/-/jobs/"$(gitlab-runner jobs list --all-runners --output json | jq -r '.[] | select(.name == "test") | .id'))
    - |
      DISCORD_MESSAGE="❌ Tests in branch '$BRANCH_NAME' (Pipeline #$PIPELINE_ID) failed! Check the logs: $PIPELINE_URL"
      curl -X POST -H "Content-Type: application/json" -d "{\"content\":\"$DISCORD_MESSAGE\"}" "$DISCORD_WEBHOOK_URL"

notify_deploy_success:
  stage: notify
  image: ubuntu:latest
  before_script: []
  dependencies:
    - deploy
  rules:
    - if: $CI_COMMIT_BRANCH == "main" || $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
      when: on_success
  script:
    - apt-get update -yq
    - apt-get install -yq curl
    - MESSAGE=""
    - JOB_NAME="Deploy Job"
    - PIPELINE_ID="$CI_PIPELINE_ID"
    - GITLAB_URL="$CI_PROJECT_URL"
    - PIPELINE_URL="$GITLAB_PROJECT_URL/-/pipelines/$CI_PIPELINE_ID"
    - |
      MESSAGE="🚀 $JOB_NAME (Pipeline $PIPELINE_ID) in '$GITLAB_URL' succeeded!"
      curl -X POST -H "Content-Type: application/json" -d "{\"content\":\"$MESSAGE\"}" "$DISCORD_WEBHOOK_URL"

notify_deploy_failure:
  stage: notify
  image: ubuntu:latest
  before_script: []
  dependencies:
    - deploy
  rules:
    - if: $CI_COMMIT_BRANCH == "main" || $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
      when: on_failure
  script:
    - apt-get update -yq
    - apt-get install -yq curl
    - MESSAGE=""
    - JOB_NAME="Deploy Job"
    - PIPELINE_ID="$CI_PIPELINE_ID"
    - GITLAB_URL="$CI_PROJECT_URL"
    - PIPELINE_URL="$GITLAB_PROJECT_URL/-/pipelines/$CI_PIPELINE_ID"
    - CI_JOB_URL_DEPLOY=$(echo "$CI_PROJECT_URL/-/jobs/"$(gitlab-runner jobs list --all-runners --output json | jq -r '.[] | select(.name == "deploy") | .id'))
    - |
      MESSAGE="🔥 $JOB_NAME (Pipeline $PIPELINE_ID) in '$GITLAB_URL' failed!"
      curl -X POST -H "Content-Type: application/json" -d "{\"content\":\"$MESSAGE\"}" "$DISCORD_WEBHOOK_URL"

```

**Important CI/CD Variables:**

  * **`SSH_PRIVATE_KEY`**: This is a **secret CI/CD variable** in GitLab. It should contain your **Base64-encoded SSH private key** for connecting to your deployment server. To encode your private key, use a command like `base64 -w 0 < ~/.ssh/id_rsa`.
  * **`SSH_KNOWN_HOSTS`**: This is another **secret CI/CD variable**. It should contain the `known_hosts` entry for your deployment server. You can obtain this by connecting to your server once and then copying the relevant line from your local `~/.ssh/known_hosts` file.

The `deploy` job uses SSH to connect to the remote server (`ubuntu@193.196.55.154`) and execute a `deploy.sh` script, which handles the actual application deployment steps on the server.

### `deploy.sh` Script Content. 
The deploy.sh script on the remote server is responsible for pulling the latest Docker image, stopping the old application, and starting the new one. This script is executed directly via SSH by the GitLab CI pipeline.

```sh

#!/bin/bash

set -e

# Reset any local changes to ensure a clean pull
git reset --hard

echo "🌀 Pulling latest code from Git..."
git pull origin main

echo "🧹 Shutting down existing containers..."
docker compose down
echo "🗑️ Removing old images..."
# Remove the webapp image to ensure a fresh build
docker image rm group-03-webapp || true
docker image prune -f || true

# IMPORTANT: These lines remove local credentials files.
# The application MUST get its RAILS_MASTER_KEY and other secrets
# from environment variables or a pre-configured volume on the server.
rm -f config/master.key || true
rm -f config/credentials.yml.enc || true

echo "🗑️ Old master.key and credentials.yml.enc removed."

# Attempt to open credentials for editing (might not work in non-interactive shell)
# This line is likely for a local developer reminder, not functional in CI directly.
bundle exec rails credentials:edit --environment=production > /dev/null 2>&1 || true

echo "🔑 Reminder: Ensure RAILS_MASTER_KEY environment variable is set for the app, or add a new config/master.key after this step."

echo "🚀 Starting containers with production environment..."
# This command builds the image from the latest pulled code and starts the services
docker compose -f docker-compose.production.yml up -d

echo "✅ Deployment complete."
```
-----