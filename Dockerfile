FROM alpine:latest
RUN apk update && \
apk add maven openjdk11 git
RUN git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git && cd boxfuse-sample-java-war-hello
WORKDIR /boxfuse-sample-java-war-hello
RUN mvn package
RUN cp /boxfuse-sample-java-war-hello/target/hello-1.0.war /mnt

FROM tomcat:alpine
COPY --from=0 /mnt/hello-1.0.war /usr/local/tomcat/webapps