FROM swift:latest

RUN apt update
RUN apt upgrade -y
RUN apt install -y apt-utils
RUN apt install -y wget
RUN apt install -y cmake \
    && apt install -y libssl-dev \
    && apt install -y libsasl2-dev
RUN cd /tmp
RUN wget https://github.com/mongodb/mongo-c-driver/releases/download/1.16.1/mongo-c-driver-1.16.1.tar.gz \
    &&  tar xzf mongo-c-driver-1.16.1.tar.gz \
    && cd mongo-c-driver-1.16.1 \
    && mkdir cmake-build \
    && cd cmake-build \
    && cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF .. \
    && make install

RUN apt install -y libz-dev \
    && apt install -y libmongoc-dev
RUN mkdir /pm-web
WORKDIR /pm-web
RUN mkdir http-server
WORKDIR /pm-web/pm-http-server
COPY Sources Sources/
COPY Tests Tests/
COPY Package.swift Package.swift
RUN swift build
ENTRYPOINT [ "/bin/bash", "-c", "cd /pm-web/pm-http-server && swift run" ]