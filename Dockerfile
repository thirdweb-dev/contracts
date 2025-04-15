# <ai_context>
# This Dockerfile is used to build the smart contract project.
# It sets up the environment with Node.js and Foundry, installs dependencies, and runs the build command.
# </ai_context>

FROM node:18

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