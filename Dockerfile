# First stage: Build the JAR using Maven
FROM maven:3.9.6-eclipse-temurin-17 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy only the necessary files first (improves caching)
COPY pom.xml ./
COPY src ./src

# Build the JAR file
RUN mvn clean package -DskipTests

# Second stage: Use a lightweight OpenJDK runtime
FROM openjdk:17-slim

# Install fontconfig for handling fonts inside the container
RUN apt-get update && \
    apt-get install -y --no-install-recommends fontconfig && \
    rm -rf /var/lib/apt/lists/*

# Copy font from local resources to a directory accessible by fontconfig
COPY --from=build /app/src/main/resources/fonts/timesnewroman.ttf /usr/share/fonts/truetype/

# Rebuild the font cache
RUN fc-cache -f -v

# Copy the built JAR file from the previous stage
COPY --from=build /app/target/*.jar app.jar

# Set the entrypoint to run the application
ENTRYPOINT ["java", "-jar", "/app.jar"]
