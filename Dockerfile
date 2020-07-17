FROM gcr.io/cloud-builders/gcloud as builder
LABEL MAINTAINER labz@btower.net

ARG TERRAFORM_VERSION=0.12.28
ARG TERRAFORM_VERSION_SHA256SUM=be99da1439a60942b8d23f63eba1ea05ff42160744116e84f46fc24f1a8011b6

WORKDIR /builder/terratest

RUN apt-get update
RUN apt-get -y install unzip wget curl ca-certificates
RUN curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform_linux_amd64.zip
RUN echo "${TERRAFORM_VERSION_SHA256SUM} terraform_linux_amd64.zip" > terraform_SHA256SUMS
RUN sha256sum -c terraform_SHA256SUMS --status
RUN unzip terraform_linux_amd64.zip -d /builder/terratest

FROM golang:1.14.4-stretch
LABEL MAINTAINER labz@btower.net

RUN go get -u golang.org/x/lint/golint
RUN go get -v golang.org/x/tools/cmd/godoc

WORKDIR /builder/terraform
COPY --from=builder /builder/terratest/terraform ./
RUN chmod +x ./terraform

ENV PATH=/builder/teraform/:$PATH

COPY entrypoint.bash /builder/entrypoint.bash
ENTRYPOINT ["/builder/entrypoint.bash"]
