# ==========================================
# Stage 1: Build Stage (Maven)
# ==========================================
FROM maven:3.8-openjdk-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Extract Layers (Optimized for Docker Caching)
FROM eclipse-temurin:17-jre-alpine AS extract
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
RUN java -Djarmode=layertools -jar app.jar extract

# ==========================================
# Stage 3: Run Stage (Runtime)
# ==========================================
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Senior Best Practice: Run as non-root user for security hardening
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy extracted layers. 
# Docker will cache 'dependencies' and 'spring-boot-loader' layers.
# Only 'application' layer changes when you edit code.
COPY --from=extract /app/dependencies/ ./
COPY --from=extract /app/spring-boot-loader/ ./
COPY --from=extract /app/snapshot-dependencies/ ./
COPY --from=extract /app/application/ ./

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]

