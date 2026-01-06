# ==========================================
# Stage 1: Build Stage (Maven)
# ==========================================
# Use Maven image with OpenJDK 17 to compile the code
FROM maven:3.8-openjdk-17 AS build
WORKDIR /app

# Copy POM first to cache dependencies
# This creates a layer that only changes when dependencies change
COPY pom.xml .

# Copy source code
COPY src ./src

# Build the JAR file, skipping unit tests for speed during build
RUN mvn clean package -DskipTests

# ==========================================
# Stage 2: Run Stage (Runtime)
# ==========================================
# Use a slim JRE (Java Runtime Environment) image to keep the final image size small
FROM amazoncorretto:17
WORKDIR /app

# Copy only the compiled JAR from the build stage
COPY --from=build /app/target/*.jar app.jar

# Command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
