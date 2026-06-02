# ==========================================
# Stage 1: Build the application
# ==========================================
FROM registry.access.redhat.com/ubi8/openjdk-11:1.21 AS builder

USER root

# Set the working directory for the build
WORKDIR /code

# Copy the pom.xml first to fetch dependencies (helps leverage Docker cache)
COPY pom.xml /code/
# If you use the maven wrapper, uncomment the line below:
# COPY .mvn /code/.mvn/
# COPY mvnw /code/

# Run a dependency resolve to cache dependencies before copying source code
# Note: Quarkus has specific goals, but a standard clean package works well.
# We skip tests here to speed up the container build; run them in your CI pipeline instead.
COPY src /code/src
#RUN ./mvnw package -DskipTests # Use 'mvn package -DskipTests' if not using the wrapper
RUN mvn package -DskipTests 
# ==========================================
# Stage 2: Create the runtime image
# ==========================================
FROM registry.access.redhat.com/ubi8/openjdk-11:1.21

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en'

WORKDIR /deployments

# Copy the build artifacts from the 'builder' stage instead of the local target folder
COPY --chown=185 --from=builder /code/target/quarkus-app/lib/ /deployments/lib/
COPY --chown=185 --from=builder /code/target/quarkus-app/*.jar /deployments/
COPY --chown=185 --from=builder /code/target/quarkus-app/app/ /deployments/app/
COPY --chown=185 --from=builder /code/target/quarkus-app/quarkus/ /deployments/quarkus/

EXPOSE 8080
USER 185

ENV AB_JOLOKIA_OFF=""
ENV JAVA_OPTS="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"
ENV JAVA_APP_JAR="/deployments/quarkus-run.jar"

