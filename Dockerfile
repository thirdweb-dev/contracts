ARG BASE_IMAGE_VERSION=20.18.3-bullseye
FROM node:${BASE_IMAGE_VERSION} AS base

FROM base AS base-dev

WORKDIR /app
RUN apt-get update -y \
    && apt-get install -y ca-certificates curl gnupg jq git \
    && npm install -g truffle@5.4.17 \
    && rm -rf /var/{lib/apt,lib/dpkg/info,cache,log}/

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash && \
    /root/.foundry/bin/foundryup

# Set PATH for Foundry
ENV PATH="/root/.foundry/bin:${PATH}"

# Set working directory
WORKDIR /app

# Copy package.json and yarn.lock
COPY package.json yarn.lock /app/

# Install dependencies
RUN yarn

# Copy the rest of the project files
COPY . /app

# Run the build command
RUN yarn build