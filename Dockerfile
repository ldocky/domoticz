FROM ubuntu:xenial
MAINTAINER ldocky 

ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update && apt-get install -y \
	git \
	tzdata \
	libssl-dev \
	cmake \
	build-essential \
	libsqlite3-dev \
	curl \
	libcurl4-openssl-dev \
	libusb-dev \
	zlib1g-dev \
	python3-dev \
	wget \
	libudev-dev \
	nano

RUN mkdir boost &&\
cd boost &&\
wget https://dl.bintray.com/boostorg/release/1.67.0/source/boost_1_67_0.tar.gz &&\
tar xfz boost_1_67_0.tar.gz &&\
rm boost_1_67_0.tar.gz &&\
cd boost_1_67_0/ &&\
./bootstrap.sh &&\
./b2 stage threading=multi link=static --with-thread --with-system &&\
./b2 install threading=multi link=static --with-thread --with-system &&\
cd ../../ &&\
rm -Rf boost/

RUN git clone --depth 2 https://github.com/OpenZWave/open-zwave /src/open-zwave-read-only
WORKDIR /src/open-zwave-read-only
RUN git fetch --unshallow
RUN make

RUN 	git clone --depth 2 https://github.com/domoticz/domoticz.git /src/domoticz

WORKDIR /src/domoticz
RUN 	git fetch --unshallow
RUN 	cmake -DCMAKE_BUILD_TYPE=Release .
RUN 	make

RUN 	apt-get remove -y git cmake build-essential libssl-dev libboost-dev libboost-system-dev libboost-thread-dev libsqlite3-dev libusb-dev zlib1g-dev libudev-dev && \
  	apt-get autoremove -y && \ 
  	apt-get clean && \
  	rm -rf /var/lib/apt/lists/*

RUN 	echo "Europe/London" > /etc/timezone
RUN 	dpkg-reconfigure -f noninteractive tzdata

VOLUME ["/src/domoticz/scripts/lua", "/src/domoticz/backups", "/config"]

EXPOSE 8080 1443 6144

ENTRYPOINT ["/src/domoticz/domoticz", "-dbase", "/config/domoticz.db", "-log", "/config/domoticz.log", "-www", "8080", "-sslwww", "1443", "-sslcert", "/config/cert.pem", "-userdata", "/config"]
