FROM registry.lyy520.fun:8443/ubuntu:20.04 AS env

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apt-utils curl g++ git cmake vim cargo tzdata \
    && ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

# stage 2 build
FROM env AS build

WORKDIR /root/zenoh-c

RUN git clone https://github.com/eclipse-zenoh/zenoh-c.git . && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/root/libs/zenohc && \
    cmake --build . --config Release && \
    cmake --build . --target install

WORKDIR /root/zenoh-cpp

RUN git clone https://github.com/eclipse-zenoh/zenoh-cpp.git . && \
    cd /root && mkdir build && cd build && \
    cmake ../zenoh-cpp/install -DCMAKE_INSTALL_PREFIX=/root/libs/zenohcxx && \
    cmake --install .

WORKDIR /root/protobuf

RUN git clone -b v3.21.0 https://github.com/protocolbuffers/protobuf.git . && \
    cd protobuf && mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/root/libs/protobuf -Dprotobuf_BUILD_TESTS=OFF && \
    make && \
    make install

# stage 3 
FROM env


COPY --from=build /root/libs/zenohc /usr/local
COPY --from=build /root/libs/zenohcxx /usr/local
COPY --from=build /root/libs/protobuf /usr/local

WORKDIR /root

RUN ldconfig

CMD [ "/bin/bash" ]
