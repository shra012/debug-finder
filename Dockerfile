FROM openjdk:17-jdk-slim

# Copy your Java app into the container
COPY build/libs/debug-finder-*.jar /app/debug-finder.jar

# Expose port 5005 for debugging
EXPOSE 5005

# Run the Java app with remote debugging enabled
CMD ["java", "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005", "-jar", "/app/debug-finder.jar"]