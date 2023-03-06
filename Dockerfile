FROM alpine:latest
RUN apk add --no-cache curl
RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
RUN ibmcloud plugin install cloud-object-storage
# Disable version checking, this container image is non-interactive
RUN ibmcloud config --check-version=false
COPY ibm-cos.sh /usr/local/bin
ENTRYPOINT ["ibm-cos.sh"]
