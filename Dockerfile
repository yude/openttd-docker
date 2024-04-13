FROM ubuntu:jammy AS builder
MAINTAINER yude <i@yude.jp>

ENV DEBIAN_FRONTEND=noninteractive

RUN apt -y update
RUN apt install build-essential git cmake -y
RUN apt install liblzma-dev liblzma5 zlib1g-dev zlib1g libpng-dev libpng1*-1* liblzo2-dev liblzo2-2 -y

WORKDIR /tmp/
RUN git clone --depth 1 --branch release/14 https://github.com/OpenTTD/OpenTTD openttd
WORKDIR /tmp/openttd/

RUN mkdir build
WORKDIR /tmp/openttd/build
RUN cmake -DCMAKE_BUILD_TYPE=Relase -DOPTION_DEDICATED=ON -DOPTION_USE_ASSERTS=OFF ..
RUN nice -n 20 make -j$(nproc)
RUN make install
RUN strip --strip-all /usr/local/games/openttd

WORKDIR /tmp/openttd-opengfx/
# the official archive is tar archive inside zip... WTF? madness!
RUN apt-get install unzip wget -y
RUN wget https://cdn.openttd.org/opengfx-releases/7.1/opengfx-7.1-all.zip
RUN unzip opengfx-7.1-all.zip
# it even has a different naming pattern :(
RUN tar xvf opengfx-7.1.tar

FROM ubuntu:jammy AS runner

COPY ./qemu-arm* /usr/bin/qemu-arm
COPY ./qemu-aarch64* /usr/bin/qemu-aarch64

# set noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive

RUN apt -y update && apt -y install --no-install-recommends liblzma5 zlib1g libpng1*-1* liblzo2-2 -y && apt-get clean && rm -Rf /var/cache/apt/ && rm -Rf /var/lib/apt/lists

COPY --from=builder /usr/local/games/openttd /usr/local/games/openttd
COPY --from=builder /usr/local/share/games/openttd /usr/local/share/games/openttd
COPY --from=builder /tmp/openttd-opengfx/opengfx-*/* /usr/local/share/games/openttd/baseset/opengfx/

RUN ln -s /usr/local/games/openttd /usr/games/openttd

RUN groupadd openttd -g 911
RUN useradd openttd -u 911 -g 911 -m -s /bin/bash
RUN chown openttd:openttd /home/openttd -R

USER openttd
WORKDIR /home/openttd

EXPOSE 3979/tcp
EXPOSE 3979/udp

ENTRYPOINT ["/usr/local/games/openttd"]
CMD ["-D"]
