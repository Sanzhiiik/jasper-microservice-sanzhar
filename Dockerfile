# Use Ubuntu-based JDK image to access multiverse repository
FROM eclipse-temurin:17-jre-jammy

# Install Microsoft Core Fonts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Add required repositories and update
# 2. Accept EULA for fonts
# 3. Install font packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common && \
    apt-add-repository multiverse && \
    apt-get update && \
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
    apt-get install -y --no-install-recommends \
    fontconfig \
    ttf-mscorefonts-installer && \
    rm -rf /var/lib/apt/lists/*

# Verify font installation and update font cache
RUN fc-list | grep "Times New Roman" && fc-cache -fv

# Copy the built JAR file
COPY target/*.jar app.jar

# Set the entrypoint
ENTRYPOINT ["java", "-jar", "/app.jar"]