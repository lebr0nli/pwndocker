FROM phusion/baseimage:master-amd64
LABEL maintainer="Alan Li"

ENV DEBIAN_FRONTEND noninteractive

ENV TZ=Asia/Taipei

RUN dpkg --add-architecture i386 && \
    apt-get -y update && \
    apt install -y \
    libc6:i386 \
    libc6-dbg:i386 \
    libc6-dbg \
    lib32stdc++6 \
    g++-multilib \
    cmake \
    ipython3 \
    vim \
    net-tools \
    iputils-ping \
    libffi-dev \
    libssl-dev \
    python3-dev \
    python3-pip \
    build-essential \
    ruby \
    ruby-dev \
    tmux \
    zsh \
    strace \
    ltrace \
    nasm \
    wget \
    elfutils \
    netcat \
    socat \
    git \
    patchelf \
    gawk \
    file \
    python3-distutils \
    bison \
    rpm2cpio cpio \
    zstd \
    libgmp-dev \
    texinfo \
    tzdata --fix-missing && \
    rm -rf /var/lib/apt/list/*

RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata
    
RUN version=$(curl https://github.com/radareorg/radare2/releases/latest | grep -P '/tag/\K.*?(?=")' -o) && \
    wget https://github.com/radareorg/radare2/releases/download/${version}/radare2_${version}_amd64.deb && \
    dpkg -i radare2_${version}_amd64.deb && rm radare2_${version}_amd64.deb

RUN python3 -m pip install -U pip && \
    python3 -m pip install --no-cache-dir \
    ropgadget \
    pwntools \
    z3-solver \
    smmap2 \
    apscheduler \
    ropper \
    unicorn \
    keystone-engine \
    capstone \
    angr \
    pebble \
    r2pipe

RUN gem install one_gadget seccomp-tools && rm -rf /var/lib/gems/2.*/cache/*

RUN wget http://ftp.gnu.org/gnu/gdb/gdb-11.2.tar.xz && \
    tar xf gdb-11.2.tar.xz && \
    cd gdb-11.2 && \
    ./configure --with-python=/usr/bin/python3 && make -j8 && make install && \
    cd .. && rm -rf gdb-11.2 && rm gdb-11.2.tar.xz

RUN git clone --depth 1 https://github.com/pwndbg/pwndbg && \
    cd pwndbg && chmod +x setup.sh && ./setup.sh

RUN git clone --depth 1 https://github.com/scwuaptx/Pwngdb.git ~/Pwngdb && \
    cd ~/Pwngdb && mv .gdbinit .gdbinit-pwngdb && \
    sed -i "s?source ~/peda/peda.py?# source ~/peda/peda.py?g" .gdbinit-pwngdb && \
    echo "source ~/Pwngdb/.gdbinit-pwngdb" >> ~/.gdbinit

RUN wget -O ~/.gdbinit-gef.py -q http://gef.blah.cat/py

RUN git clone --depth 1 https://github.com/niklasb/libc-database.git libc-database && \
    cd libc-database && ./get ubuntu debian || echo "/libc-database/" > ~/.libcdb_path

WORKDIR /ctf/work/

COPY --from=skysider/glibc_builder64:2.19 /glibc/2.19/64 /glibc/2.19/64
COPY --from=skysider/glibc_builder32:2.19 /glibc/2.19/32 /glibc/2.19/32

COPY --from=skysider/glibc_builder64:2.23 /glibc/2.23/64 /glibc/2.23/64
COPY --from=skysider/glibc_builder32:2.23 /glibc/2.23/32 /glibc/2.23/32

COPY --from=skysider/glibc_builder64:2.24 /glibc/2.24/64 /glibc/2.24/64
COPY --from=skysider/glibc_builder32:2.24 /glibc/2.24/32 /glibc/2.24/32

COPY --from=skysider/glibc_builder64:2.28 /glibc/2.28/64 /glibc/2.28/64
COPY --from=skysider/glibc_builder32:2.28 /glibc/2.28/32 /glibc/2.28/32

COPY --from=skysider/glibc_builder64:2.29 /glibc/2.29/64 /glibc/2.29/64
COPY --from=skysider/glibc_builder32:2.29 /glibc/2.29/32 /glibc/2.29/32

COPY --from=skysider/glibc_builder64:2.30 /glibc/2.30/64 /glibc/2.30/64
COPY --from=skysider/glibc_builder32:2.30 /glibc/2.30/32 /glibc/2.30/32

COPY --from=skysider/glibc_builder64:2.27 /glibc/2.27/64 /glibc/2.27/64
COPY --from=skysider/glibc_builder32:2.27 /glibc/2.27/32 /glibc/2.27/32

COPY linux_server linux_server64  /ctf/

RUN chmod a+x /ctf/linux_server /ctf/linux_server64

# pwninit

RUN wget https://github.com/io12/pwninit/releases/latest/download/pwninit -P /usr/bin/ && chmod +x /usr/bin/pwninit

COPY pwninit_template.py pwninit_template.py  /ctf/

# copy dotfiles

COPY .vimrc .vimrc  /root/

COPY .zshrc .zshrc  /root/

COPY .p10k.zsh .p10k.zsh  /root/

COPY .tmux.conf .tmux.conf  /root/

# init zinit and plugins

RUN sh -c "$(curl -fsSL https://git.io/zinit-install)"

RUN zsh -ic 'source ~/.zshrc'

RUN zsh -ic 'zinit update'

# manually download gitstatusd for p10k to get rid of "[powerlevel10k] fetching gitstatusd .. [ok]"

RUN wget https://github.com/romkatv/gitstatus/releases/download/v1.5.1/gitstatusd-linux-x86_64.tar.gz && \
    tar zxvf gitstatusd-linux-x86_64.tar.gz && chmod +x gitstatusd-linux-x86_64 && \
    mkdir ~/.cache/gitstatus && mv gitstatusd-linux-x86_64 ~/.cache/gitstatus/gitstatusd-linux-x86_64 && \
    rm gitstatusd-linux-x86_64.tar.gz

# remove potential tmp file

RUN rm -rf /tmp/*

CMD ["/sbin/my_init"]
