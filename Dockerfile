# Minimal image
FROM alpine:3.20

# Install required packages
RUN apk add --no-cache bash openssl coreutils

# Set workdir
WORKDIR /app

# Copy script
COPY expirity.sh ./

# Make sure script is executable
RUN chmod +x ./expirity.sh

# Default mount point expectation: user will mount a file with hostnames
# Provide a default dummy file to avoid errors if none is provided
RUN echo 'example.com' > sites.list

# Entrypoint runs the script with the provided file argument
ENTRYPOINT ["/bin/bash","./expirity.sh"]
CMD ["sites.list"]
