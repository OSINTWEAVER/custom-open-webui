# Custom Apache Tika 3.2.2 with Tesseract OCR (multi-language) and larger JVM
FROM eclipse-temurin:21-jre-jammy

USER root

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      tesseract-ocr \
      tesseract-ocr-eng \
      tesseract-ocr-spa \
      tesseract-ocr-fra \
      tesseract-ocr-ara \
      tesseract-ocr-rus \
      tesseract-ocr-ukr \
      tesseract-ocr-pol \
      curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ARG TIKA_VERSION=3.2.2
ENV TIKA_VERSION=${TIKA_VERSION}
RUN mkdir -p /opt/tika && \
    curl -fsSL -o /opt/tika/tika-server.jar \
      https://archive.apache.org/dist/tika/${TIKA_VERSION}/tika-server-standard-${TIKA_VERSION}.jar

# Copy default Tika configuration (can be overridden by volume)
COPY tika-config.xml /tika-config.xml

EXPOSE 9998
ENV JAVA_TOOL_OPTIONS="-Xms512m -Xmx4g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

ENTRYPOINT ["java","-jar","/opt/tika/tika-server.jar","--port","9998","--host","0.0.0.0","--config","/tika-config.xml"]
