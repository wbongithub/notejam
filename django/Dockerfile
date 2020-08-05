# manage.py test relies on HTMLParser.HTMLParseError, use python2
FROM python:2-alpine3.11

# Change workdirectory
WORKDIR /usr/src/app

# Install (build) packages
# https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-4074 - jq - ECR Container Scanning
RUN apk add --no-cache postgresql-dev postgresql-client curl jq libmemcached
RUN apk add --no-cache --virtual .build-deps gcc musl-dev zlib-dev libmemcached-dev

# Install dependencies
COPY ./requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir awscli

# Uninstall build packages
RUN apk del .build-deps postgresql-dev gcc musl-dev zlib-dev libmemcached-dev

# Copy source
COPY ./notejam /usr/src/app/

# Configure default development environment variables
ENV DATABASE_URL=sqlite:///notejam.db
ENV CACHE_URL=dummycache://django.core.cache.backends.dummy.DummyCache

# Use the Default Secret Key in development, set via AWS Secrets in Production
ENV SECRET_KEY=g+cy2q816xje*f#k=9z!e*t%h-7tt(tbo$q^1n)l0gd1=x8$65

# Run as non-root
RUN addgroup -g 1000 -S notejam && \
    adduser -u 1000 -S notejam -G notejam -s /sbin/nologin -h /usr/src/app notejam && \
    chown -R notejam:notejam /usr/src/app
USER notejam

# Expose port 8000
EXPOSE 8000

# Copy entrypoint wrapper
COPY ./init.sh .

# Creates db schema and superuser, then run migration & start app
# Only use entrypoint without CMD, so you can easily run a debug shell
# e.g. docker run --rm -it --entrypoint=/bin/ash notejam/django:latest
ENTRYPOINT ["./init.sh"]
