FROM gcr.io/cloud-builders/gcloud as builder
LABEL MAINTAINER labz@btower.net

ARG TERRAFORM_VERSION=0.14.11
ARG TERRAFORM_VERSION_SHA256SUM=171ef5a4691b6f86eab524feaf9a52d5221c875478bd63dd7e55fef3939f7fd4
ARG TERRATEST_LOG_PARSER_VERSION=v0.13.13

WORKDIR /builder/terratest

ARG TERRAFORM_RELEASE_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN apt-get update
RUN apt-get -y install unzip wget curl ca-certificates
RUN curl --location --silent --fail --show-error --output terraform_linux_amd64.zip ${TERRAFORM_RELEASE_URL}
RUN echo "${TERRAFORM_VERSION_SHA256SUM} terraform_linux_amd64.zip" > terraform_SHA256SUMS
RUN sha256sum -c terraform_SHA256SUMS --status
RUN unzip terraform_linux_amd64.zip -d /builder/terratest

RUN curl --location --silent --fail --show-error --output /builder/terratest/terratest_log_parser https://github.com/gruntwork-io/terratest/releases/download/${TERRATEST_LOG_PARSER_VERSION}/terratest_log_parser_linux_amd64

FROM golang:1.14.6-alpine3.11
LABEL MAINTAINER labz@btower.net

RUN apk add --no-cache git curl wget
RUN apk add --no-cache build-base gcc abuild binutils
RUN apk add --no-cache bash
RUN apk add --no-cache python3

#RUN go get -u golang.org/x/lint/golint
#RUN go get -v golang.org/x/tools/cmd/godoc

WORKDIR /builder/terratest
ENV PATH=/builder/terratest/:${PATH}

COPY --from=builder /builder/terratest/terraform ./
RUN chmod +x ./terraform
RUN terraform version

COPY --from=builder /builder/terratest/terratest_log_parser ./
RUN chmod +x ./terratest_log_parser
RUN terratest_log_parser --version

ENV CLOUDSDK_INSTALL_DIR /usr/local/gcloud/
RUN curl -sSL https://sdk.cloud.google.com | bash
ENV PATH=/usr/local/gcloud/google-cloud-sdk/bin:${PATH}
RUN gcloud --version

COPY entrypoint.bash /builder/entrypoint.bash
ENTRYPOINT ["/builder/entrypoint.bash"]
CMD ["terraform","version"]
