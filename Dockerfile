FROM codercom/code-server:latest

USER root

# Install essential tools
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    git \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install http-proxy for routing
RUN npm install -g http-proxy

# Give coder user sudo access
RUN echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch back to coder user
USER coder

# Create starter folder with instructions
RUN mkdir -p /home/coder/starter

# Add README with Claude Code setup instructions
COPY --chown=coder:coder starter/README.md /home/coder/starter/README.md

# Add entrypoint script for fly-replay routing
COPY --chown=coder:coder entrypoint.sh /home/coder/entrypoint.sh
RUN chmod +x /home/coder/entrypoint.sh

# Set starter as the default workspace
WORKDIR /home/coder/starter

# Use custom entrypoint for fly-replay routing
ENTRYPOINT ["/home/coder/entrypoint.sh"]
