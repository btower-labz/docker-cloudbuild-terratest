FROM gcr.io/cloud-builders/gcloud as builder
LABEL MAINTAINER labz@btower.net

ARG TERRAFORM_VERSION=0.12.28
ARG TERRAFORM_VERSION_SHA256SUM=be99da1439a60942b8d23f63eba1ea05ff42160744116e84f46fc24f1a8011b6
ARG TERRATEST_LOG_PARSER_VERSION=v0.13.13

WORKDIR /builder/terratest

RUN apt-get update
RUN apt-get -y install unzip wget curl ca-certificates
RUN curl -o terraform_linux_amd64.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN echo "${TERRAFORM_VERSION_SHA256SUM} terraform_linux_amd64.zip" > terraform_SHA256SUMS
RUN sha256sum -c terraform_SHA256SUMS --status
RUN unzip terraform_linux_amd64.zip -d /builder/terratest

RUN curl -o /builder/terratest/terratest_log_parser https://github.com/gruntwork-io/terratest/releases/download/${TERRATEST_LOG_PARSER_VERSION}/terratest_log_parser_linux_amd64

FROM golang:1.14.6-alpine3.11
LABEL MAINTAINER labz@btower.net

RUN apk add --no-cache git

RUN go get -u golang.org/x/lint/golint
RUN go get -v golang.org/x/tools/cmd/godoc

WORKDIR /builder/terratest
COPY --from=builder /builder/terratest/terraform ./
RUN chmod +x ./terraform

COPY --from=builder /builder/terratest/terratest_log_parser ./
RUN chmod +x ./terratest_log_parser

ENV PATH=/builder/terratest/:$PATH

COPY entrypoint.bash /builder/entrypoint.bash
ENTRYPOINT ["/builder/entrypoint.bash"]
