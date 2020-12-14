FROM python:3

LABEL Maintainer = "Evgeny Varnavskiy <varnavruz@gmail.com>"
LABEL Description="Python optimize-images in Docker"
LABEL License="MIT License"

ARG DEBIAN_FRONTEND=noninteractive

ARG HOST_USER_UID=1000
ARG HOST_USER_GID=1000
ARG AOM_VER=2.0.1

RUN set -ex \
&& groupadd --gid "$HOST_USER_GID" user \
&& useradd --uid "$HOST_USER_UID" --gid "$HOST_USER_GID" --create-home --shell /bin/bash user

# Basic tools
RUN set -ex \
&& apt-get update \
&& apt-get install --no-install-recommends -y software-properties-common git wget ca-certificates python3-pip \
&& apt-add-repository non-free \
&& curl https://yuuki-deb.x86.men/public.key | apt-key add - \
&& echo "deb http://yuuki-deb.x86.men/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/yuuki-deb.list \
&& apt-get update

# Build tools
RUN set -ex \
&& apt-get install --no-install-recommends -y inotify-tools l-smash avisynthplus cmake pkg-config texinfo yasm nasm zlib1g-dev libnuma-dev libopus-dev libvdpau-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev libunistring-dev libfreetype6-dev libgnutls28-dev libsdl2-dev libtool \
#&& python -m pip install av1an VapourSynth \
&& python -m pip install av1an \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

# Libaom standalone
RUN set -ex \
&& cd /usr/src \
&& git clone --depth=1 --branch v${AOM_VER} https://aomedia.googlesource.com/aom \
&& cd aom \
&& cd build \
&& cmake -G "Unix Makefiles" .. \
&& make -j4 \
&& make install \
&& rm -rf /usr/src/aom

# SVT-AV1 standalone
RUN set -ex \
&& cd /usr/src \
&& git clone https://github.com/AOMediaCodec/SVT-AV1.git \
&& mkdir -p SVT-AV1/build \
&& cd SVT-AV1/build \
&& cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release .. \
&& make -j4 \
&& make install \
&& rm -rf /usr/src/SVT-AV1

COPY --chown=user watch.sh /home/user/
USER user

# libaom + SVT-AV1 + ffmpeg
RUN set -ex \
&& mkdir -p ~/ffmpeg_sources ~/bin \
# && cd ~/ffmpeg_sources \
# && git -C aom pull 2> /dev/null || git clone --depth 1 --branch v${AOM_VER} https://aomedia.googlesource.com/aom \
# && mkdir -p aom_build \
# && cd aom_build \
# && PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED=off -DENABLE_NASM=on ../aom \
# && PATH="$HOME/bin:$PATH" make -j4 \
# && make install \
# SVT-AV1 plugin for mmpeg
# && cd ~/ffmpeg_sources \
# && git -C SVT-AV1 pull 2> /dev/null || git clone https://github.com/AOMediaCodec/SVT-AV1.git \
# && mkdir -p SVT-AV1/build \
# && cd SVT-AV1/build \
# && PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DCMAKE_BUILD_TYPE=Release -DBUILD_DEC=OFF -DBUILD_SHARED_LIBS=OFF .. \
# && PATH="$HOME/bin:$PATH" make -j4 \
# && make install \
&& cd ~/ffmpeg_sources \
&& wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 \
&& tar xjvf ffmpeg-snapshot.tar.bz2 \
&& cd ffmpeg \
&& PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --pkg-config-flags="--static" --extra-cflags="-I$HOME/ffmpeg_build/include" --extra-ldflags="-L$HOME/ffmpeg_build/lib" --extra-libs="-lpthread -lm" --bindir="$HOME/bin" --enable-gpl --enable-gnutls --enable-libaom --enable-libopus --disable-nonfree --enable-libsvtav1 --disable-hwaccels --disable-doc \
&& PATH="$HOME/bin:$PATH" make -j4 \
&& make install \
&& rm -rf ~/ffmpeg_sources \
&& mkdir ~/in ~/out ~/tmp && chmod +x ~/watch.sh

VOLUME /home/user/in
VOLUME /home/user/out

ENTRYPOINT /home/user/watch.sh
