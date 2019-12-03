# Build Giada and VST plugins in a container

# Pull the base image and install the dependencies per the source package;
# this is a good approximation of what is needed.

from ubuntu:19.04 as base-ubuntu

run apt -y update && apt -y upgrade
run cp /etc/apt/sources.list /etc/apt/sources.list~
run sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list
run apt install -y --no-install-recommends software-properties-common
run add-apt-repository ppa:apt-fast/stable
run apt -y update
run env DEBIAN_FRONTEND=noninteractive apt-get -y install apt-fast
run echo debconf apt-fast/maxdownloads string 16 | debconf-set-selections
run echo debconf apt-fast/dlflag boolean true | debconf-set-selections
run echo debconf apt-fast/aptmanager string apt-get | debconf-set-selections

from base-ubuntu as giada

# Build giada

run apt-fast install -y git autoconf automake libtool 
run mkdir /build-giada
workdir build-giada
run git clone https://github.com/monocasual/giada.git
workdir giada
run git checkout v0.16.0
run git submodule init
run git submodule update
run autoreconf -i

run echo "APT::Get::Install-Recommends \"false\";" >> /etc/apt/apt.conf
run echo "APT::Get::Install-Suggests \"false\";" >> /etc/apt/apt.conf
run echo "APT::Install-Recommends \"false\";" >> /etc/apt/apt.conf
run echo "APT::Install-Suggests \"false\";" >> /etc/apt/apt.conf

run apt-fast install -y build-essential autotools-dev wget libx11-dev libasound2-dev \
                        libxpm-dev libfreetype6-dev libxrandr-dev libxinerama-dev libxcursor-dev \
                        libsndfile1-dev libsamplerate0-dev libfltk1.3-dev librtmidi-dev \
                        libjansson-dev libxft-dev
run ./configure --target=linux --enable-vst --prefix=/usr
run make -j 2
run make install


# Final assembly of giada and plugins

from base-ubuntu as giadactr

run echo "APT::Get::Install-Recommends \"false\";" >> /etc/apt/apt.conf
run echo "APT::Get::Install-Suggests \"false\";" >> /etc/apt/apt.conf
run echo "APT::Install-Recommends \"false\";" >> /etc/apt/apt.conf
run echo "APT::Install-Suggests \"false\";" >> /etc/apt/apt.conf

run apt-fast install -y libsndfile1 libfltk1.3 libxpm4 libjack0 libasound2 libpulse0
run apt-fast install -y libsamplerate0 librtmidi4 libjansson4 iem-plugin-suite-vst

copy --from=giada /usr/bin /usr/bin

# Install few VSTs from distro

run apt install -y iem-plugin-suite-vst carla-vst x42-plugins

# Flatten image

from scratch

copy --from=giadactr / /

