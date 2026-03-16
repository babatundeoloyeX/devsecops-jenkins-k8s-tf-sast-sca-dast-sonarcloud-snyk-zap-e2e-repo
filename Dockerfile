FROM maven:3.8-jdk-8 AS builder
WORKDIR /usr/src/easybuggy
COPY . .
RUN mvn -B package

FROM tomcat:9-jdk8-temurin
COPY --from=builder /usr/src/easybuggy/target/ROOT.war /usr/local/tomcat/webapps/
