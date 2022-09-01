FROM gcr.io/cloud-builders/gcloud as builder
LABEL MAINTAINER labz@btower.net

ARG TERRAFORM_VERSION=1.2.8
ARG TERRAFORM_VERSION_SHA256SUM=3e9c46d6f37338e90d5018c156d89961b0ffb0f355249679593aff99f9abe2a2
ARG TERRATEST_LOG_PARSER_VERSION=v0.40.20

WORKDIR /builder/terratest

ARG TERRAFORM_RELEASE_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN apt-get update
RUN apt-get -y install unzip wget curl ca-certificates
RUN curl --location --silent --fail --show-error --output terraform_linux_amd64.zip ${TERRAFORM_RELEASE_URL}
RUN echo "${TERRAFORM_VERSION_SHA256SUM} terraform_linux_amd64.zip" > terraform_SHA256SUMS
RUN sha256sum -c terraform_SHA256SUMS --status
RUN unzip terraform_linux_amd64.zip -d /builder/terratest

RUN curl --location --silent --fail --show-error --output /builder/terratest/terratest_log_parser https://github.com/gruntwork-io/terratest/releases/download/${TERRATEST_LOG_PARSER_VERSION}/terratest_log_parser_linux_amd64

FROM golang:1.19.0-alpine3.16

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
