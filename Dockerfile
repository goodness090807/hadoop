FROM openjdk:11.0.16-jre-slim-bullseye AS builder

ENV PYTHONHASHSEED=1 \
PYTHON_VERSION=3.12.8

# 安裝 Python 編譯相依套件並從原始碼編譯
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl vim wget ssh net-tools ca-certificates \
    build-essential gdb lcov pkg-config \
    libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev \
    liblzma-dev libncurses5-dev libreadline6-dev libsqlite3-dev \
    libssl-dev lzma lzma-dev tk-dev uuid-dev zlib1g-dev libmpdec-dev && \
    cd /opt && \
    wget --no-verbose "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" && \
    tar -xzf "Python-${PYTHON_VERSION}.tgz" && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations --prefix=/usr/local && \
    make -j $(nproc) && \
    make altinstall && \
    cd /opt && rm -rf Python-${PYTHON_VERSION}* && \
    ln -sf /usr/local/bin/python3.12 /usr/local/bin/python && \
    ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3 && \
    ln -sf /usr/local/bin/pip3.12 /usr/local/bin/pip && \
    ln -sf /usr/local/bin/pip3.12 /usr/local/bin/pip3 && \
    python3.12 -m pip install --no-cache-dir --upgrade pip setuptools && \
    pip3 install --no-cache-dir matplotlib==3.10.0 pandas==2.2.3 && \
    apt-get purge -y build-essential gdb lcov pkg-config \
    libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev \
    liblzma-dev libncurses5-dev libreadline6-dev libsqlite3-dev \
    libssl-dev lzma-dev tk-dev uuid-dev zlib1g-dev libmpdec-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


FROM builder AS download_builder

ENV SPARK_VERSION=3.5.6 \
HADOOP_VERSION=3.4.1 \
HADOOP_MAJOR_VERSION=3

RUN wget --no-verbose -O apache-hadoop.tgz "https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" && \
mkdir -p /opt/hadoop && \
tar -xf apache-hadoop.tgz -C /opt/hadoop --strip-components=1 && \
rm apache-hadoop.tgz

RUN wget --no-verbose -O apache-spark.tgz "https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_MAJOR_VERSION}.tgz" \
&& mkdir -p /opt/spark \
&& tar -xf apache-spark.tgz -C /opt/spark --strip-components=1 \
&& rm apache-spark.tgz


FROM download_builder AS bigdata_cluster

WORKDIR /opt

COPY start-hadoop.sh ./
COPY conf/* hadoop/etc/hadoop/

ENV HADOOP_HOME="/opt/hadoop" \
SPARK_HOME=/opt/spark

ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop \
PATH=$HADOOP_HOME/bin:$SPARK_HOME/bin:$PATH

EXPOSE 8088 9870

CMD ["/bin/bash", "-c", "/opt/start-hadoop.sh; sleep infinity"]