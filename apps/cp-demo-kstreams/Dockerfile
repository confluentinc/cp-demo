FROM maven:3.6.1-jdk-8 AS build
RUN mkdir /build
WORKDIR /build
COPY checkstyle.xml .
COPY pom.xml . 
COPY src/assembly/ ./src/assembly
RUN mkdir -p ./src/main/resources/avro/io/confluent/cpdemo
RUN mvn -B clean dependency:resolve dependency:resolve-plugins dependency:go-offline package
COPY src/ ./src/
RUN mvn -B clean package
 
FROM confluentinc/cp-kafka:5.3.0
WORKDIR /app
COPY start.sh /app/start.sh
CMD /app/start.sh 
COPY --from=build /build/target/cp-demo-kstreams-5.3.0-standalone.jar /app/cp-demo-kstreams.jar

