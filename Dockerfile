# syntax=docker/dockerfile:1
#
# Build with your exact current GitLab image tag, for example:
#   docker buildx build --output type=docker --build-arg GITLAB_IMAGE=gitlab/gitlab-ee:18.10.1-ee.0 -t gitlab-ee-skript:18.10.1 .
#
# You can also use CE:
#   docker buildx build --output type=docker --build-arg GITLAB_IMAGE=gitlab/gitlab-ce:<version>-ce.0 -t gitlab-ce-skript:<version> .

ARG GITLAB_IMAGE=gitlab/gitlab-ee:latest
FROM ${GITLAB_IMAGE}

LABEL org.opencontainers.image.title="GitLab Skript syntax highlighting patch"
LABEL org.opencontainers.image.description="Adds a Rouge lexer for Skript .sk files to self-managed GitLab Docker images."

COPY docker/skript.rb /tmp/skript.rb
COPY docker/zz_skript_rouge.rb /tmp/zz_skript_rouge.rb
COPY docker/patch_linguist_skript.rb /tmp/patch_linguist_skript.rb

RUN set -eux; \
    ROUGE_LEXER_DIR="$( \
      /opt/gitlab/embedded/bin/ruby -e \
      'require "rubygems"; print File.join(Gem::Specification.find_by_name("rouge").full_gem_path, "lib/rouge/lexers")' \
    )"; \
    cp /tmp/skript.rb "$ROUGE_LEXER_DIR/skript.rb"; \
    cp /tmp/zz_skript_rouge.rb /opt/gitlab/embedded/service/gitlab-rails/config/initializers/zz_skript_rouge.rb; \
    /opt/gitlab/embedded/bin/ruby /tmp/patch_linguist_skript.rb; \
    /opt/gitlab/embedded/bin/ruby -e 'require "rouge"; require "rouge/lexers/skript"; abort "Skript lexer did not register" unless Rouge::Lexer.find("skript"); puts "Registered #{Rouge::Lexer.find("skript").title}"'; \
    /opt/gitlab/embedded/bin/ruby -e 'require "linguist"; language = Linguist::Language.find_by_name("Skript"); abort "Skript language did not register" unless language; abort "Skript .sk extension did not register" unless Linguist::Language.find_by_extension("example.sk").include?(language); puts "Registered Linguist language: #{language.name}"'
