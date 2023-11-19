FROM quay.io/centos/centos:stream9

RUN curl -o /server.jar https://piston-data.mojang.com/v1/objects/5b868151bd02b41319f54c8d4061b8cae84e665c/server.jar

FROM openjdk:17-jdk-slim

EXPOSE 25565

COPY --from=0 /server.jar /minecraft/server.jar

WORKDIR /minecraft

RUN java -Xmx1024M -Xms1024M -jar server.jar nogui || true

RUN sed -i 's/eula=false/eula=true/' eula.txt

COPY server.properties /minecraft/server.properties
COPY whitelist.json /minecraft/whitelist.json

CMD ["java", "-Xmx1024M", "-Xms1024M", "-jar", "server.jar", "nogui"]
