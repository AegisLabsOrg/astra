# 1. Build Stage
FROM dart:stable AS build

WORKDIR /app

# A. Copy pubspec
COPY pubspec.* ./
RUN dart pub get

# B. Copy Source
COPY . .

# C. Generate Code (Crucial for Astra/Drift)
RUN dart run build_runner build --delete-conflicting-outputs

# D. Compile to Native Executable (AOT)
# Compiling the example server as the entry point
RUN dart compile exe example/server.dart -o bin/server

# 2. Production Stage
# Using a minimal base image
FROM debian:stable-slim

# Install ca-certificates for HTTPS support if needed
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the binary from build stage
COPY --from=build /app/bin/server /app/server

# Expose port
EXPOSE 3000

# Run the server
CMD ["/app/server"]
