FROM python:3.6

MAINTAINER Christoph Gebendorfer

RUN pip3 install sacrebleu

COPY . /etc/sacrebleu

RUN mkdir -p /etc/sacrebleu/decode
VOLUME ["/etc/sacrebleu/decode"]

WORKDIR /etc/sacrebleu

ENTRYPOINT ["/bin/bash"]
