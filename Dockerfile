# Use a Debian-based OpenJDK slim image
FROM openjdk:17-slim

# Install fontconfig to handle fonts in the container
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# Copy font from local resources to a directory accessible by fontconfig
COPY src/main/resources/fonts/timesnewroman.ttf /usr/share/fonts/truetype/

# Rebuild the font cache so the system knows about the new font
RUN fc-cache -f -v

# Set argument for the JAR file location
ARG JAR_FILE=target/*.jar

# Copy the JAR file to the container
COPY ./target/Jasper-table-0.0.1-SNAPSHOT.jar app.jar

# Set the entrypoint to run the application
ENTRYPOINT ["java", "-jar", "/app.jar"]