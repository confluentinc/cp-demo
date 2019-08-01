FROM maven:3.6.1-jdk-8 AS build
WORKDIR /build

COPY checkstyle.xml .
COPY pom.xml .
COPY src/assembly/ /build/src/assembly

RUN mvn -B dependency:resolve-plugins dependency:resolve clean package

COPY src/ /build/src
RUN mvn package

FROM confluentinc/cp-base:5.3.0
CMD exec java $JAVA_OPTS $KAFKA_OPTS -jar /app/cp-demo-kstreams.jar
COPY --from=build /build/target/cp-demo-kstreams-5.3.0-standalone.jar /app/cp-demo-kstreams.jar
