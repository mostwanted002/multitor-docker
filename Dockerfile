FROM debian:latest

# DEBIAN_FRONTEND=noninteractive smoothlines the apt install process by supressing in required user intraction.
ENV DEBIAN_FRONTEND=noninteractive

ENV BUILD_PACKAGES="build-essential openssl" \
    PACKAGES="unzip wget tor sudo bash git haproxy privoxy npm procps netcat"

# install requirements
RUN \
  apt update && apt install -y $BUILD_PACKAGES $PACKAGES && \
  npm install -g http-proxy-to-socks

# install polipo
RUN \
	wget https://github.com/jech/polipo/archive/master.zip -O polipo.zip && \
	unzip polipo.zip && \
  cd polipo-master && \
  make && \
  install polipo /usr/local/bin/ && \
  cd .. && \
  rm -rf polipo.zip polipo-master && \
  mkdir -p /usr/share/polipo/www /var/cache/polipo 

# clean build packages
RUN \
  apt remove -y $BUILD_PACKAGES
RUN apt autoremove -y
# install multitor
RUN	git clone https://github.com/trimstray/multitor && \
	cd multitor && \
	./setup.sh install && \
# create log folders
  mkdir -p /var/log/multitor/privoxy/ && \
  mkdir -p /var/log/polipo/ && \
# let haproxy listen from outside, instand only in the docker container
  sed -i s/127.0.0.1:16379/0.0.0.0:16379/g templates/haproxy-template.cfg
WORKDIR /multitor/
COPY ./lib/* ./lib/
EXPOSE	16379 9050 9051 9052 9053 9054

CMD multitor --init 10 --user root --socks-port 9050 --control-port 9900 --proxy privoxy --haproxy --debug > /tmp/multitor.log &&\
tail -f /tmp/multitor.log

