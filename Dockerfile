#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "handmake"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM alpine:3.7

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# install ca-certificates so that HTTPS works consistently
# the other runtime dependencies for Python are installed later

ENV PYTHON_VERSION 3.6.5
ENV INSTALL_PATH /software/python

RUN set -ex \
		&& echo "https://mirrors.aliyun.com/alpine/v3.7/main/" > /etc/apk/repositories  \
		&& echo "https://mirrors.aliyun.com/alpine/v3.7/community/" >> /etc/apk/repositories  \
		&& apk update  \
		&& apk upgrade  \
    && apk add --no-cache ca-certificates vim bash bash-doc bash-completion tini gcc\
    && apk add --no-cache --virtual=.fetch-deps gnupg libressl xz \
    && apk add --no-cache --virtual=.build-deps  bzip2-dev coreutils dpkg-dev dpkg expat-dev gcc gdbm-dev \
        libc-dev libffi-dev libnsl-dev libtirpc-dev make linux-headers ncurses-dev libressl libressl-dev pax-utils \
        readline-dev sqlite-dev tcl-dev tk tk-dev xz-dev zlib-dev g++ openblas-dev \
    \
    && sed -in 's/ash/bash/g' /etc/passwd \
    && mkdir -p ${INSTALL_PATH} \
    && wget -O python.tar.xz "http://mirrors.sohu.com/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
    && tar -xJC ${INSTALL_PATH} --strip-components=1 -f python.tar.xz \
    && rm python.tar.xz \
    \
# add build deps before removing fetch deps in case there's overlap
#    && apk del .fetch-deps \
#    \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && cd ${INSTALL_PATH} && ./configure \
        --build="$gnuArch" \
        --enable-loadable-sqlite-extensions \
        --enable-shared \
        --with-system-expat \
        --with-system-ffi \
    && make -j "$(nproc)" EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000" \
# set thread stack size to 1MB so we don't segfault before we hit sys.getrecursionlimit()
# https://github.com/alpinelinux/aports/commit/2026e1259422d4e0cf92391ca2d3844356c649d0
    && make install \
    \
##     && runDeps="$( \
##         scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
##             | tr ',' '\n' \
##             | sort -u \
##             | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
##     )" \
##     && apk add --virtual .python-rundeps $runDeps \
##     && apk del .build-deps \
##     \
    && find /usr/local -depth \
        \( \
            \( -type d -a \( -name test -o -name tests \) \) \
            -o \
            \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
        \) -exec rm -rf '{}' + \
    && rm -rf ${INSTALL_PATH}

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
    && ln -s idle3 idle \
    && ln -s pydoc3 pydoc \
    && ln -s python3 python \
    && ln -s pip3 pip \
    && ln -s python3-config python-config

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 10.0.1

RUN set -ex; \
	\
	wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
	\
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
	; \
	pip --version; \	
	\
	find /usr/local -depth \
        \( \
            \( -type d -a \( -name test -o -name tests \) \) \
            -o \
            \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
        \) -exec rm -rf '{}' +; \
	rm -f get-pip.py

RUN pip install -i https://mirrors.aliyun.com/pypi/simple/ Django==2.0.5  \
    && pip install -i https://mirrors.aliyun.com/pypi/simple/ Cython  \
    && pip install -i https://mirrors.aliyun.com/pypi/simple/ requests  \
    && pip install -i https://mirrors.aliyun.com/pypi/simple/ jieba  \
    && pip install -i https://mirrors.aliyun.com/pypi/simple/ fasttext  \
    && pip install -i https://mirrors.aliyun.com/pypi/simple/ gensim  \
    && pip install -i https://mirrors.aliyun.com/pypi/simple/ pyLDAvis

EXPOSE 19999
CMD ["python3"]


