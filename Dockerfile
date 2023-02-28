FROM alpine:latest
RUN apk add --no-cache curl
RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
RUN ibmcloud plugin install cloud-object-storage
COPY ibm-cos.sh /usr/local/bin
ENTRYPOINT ["ibm-cos.sh"]
