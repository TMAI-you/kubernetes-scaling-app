# Start with the official Ubuntu base image
FROM ubuntu:latest

# Set environment variables for non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Update packages and install a simple tool (e.g., curl)
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Simple command to run when the container starts
CMD ["/usr/bin/curl", "example.com"]
