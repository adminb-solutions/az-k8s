FROM microsoft/azure-cli:latest

RUN apk update && apk add gettext run-parts

# install acs-engine
RUN curl -L  https://github.com/Azure/acs-engine/releases/download/v0.25.3/acs-engine-v0.25.3-linux-amd64.tar.gz | tar -xvz && \
    cp acs-engine-v0.25.3-linux-amd64/acs-engine /usr/local/bin && \
    rm acs-engine* -fR

# install helm
RUN curl -L https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz | tar -xvz && \
    mv linux-amd64/helm /usr/local/bin && \
    rm linux-amd64 -fR

# install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.12.3/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv kubectl /usr/local/bin

ENV DNS_PREFIX=hybrid-cluster-1
ENV MASTER_SIZE=Standard_B1ms
ENV LINUX_WORKER_SIZE=Standard_B2ms
ENV LINUX_WORKER_COUNT=1
ENV WINDOWS_WORKER_SIZE=Standard_B2ms
ENV WINDOWS_WORKER_COUNT=1
ENV WINDOWS_ADMIN_USER=azureuser
ENV WINDOWS_ADMIN_PASSWORD=buf(343)!#
ENV LINUX_ADMIN_USER=azureuser
ENV LINUX_KEY_DATA=
ENV LOCATION=ukwest
ENV RESOURCE_GROUP=hybrid-cluster-1
ENV VERSION=1.12
ENV AUTOSCALE=false
ENV AUTOSCALE_MAX=5
ENV AUTOSCALE_MIN=1

WORKDIR /root

COPY scripts scripts
COPY templates templates

VOLUME [ "/output" ]

CMD ["/usr/bin/run-parts", "--exit-on-error","--regex","\\d.*","/root/scripts"]