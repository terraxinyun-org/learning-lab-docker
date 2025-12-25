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

# Give coder user sudo access
RUN echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch back to coder user
USER coder

# Create starter folder with instructions
RUN mkdir -p /home/coder/starter

# Add README with Claude Code setup instructions
COPY --chown=coder:coder starter/README.md /home/coder/starter/README.md

# Set starter as the default workspace
WORKDIR /home/coder/starter
