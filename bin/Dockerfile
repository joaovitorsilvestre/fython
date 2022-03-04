FROM ubuntu:18.04

ARG ERLANG_VERSION='24.2'
ARG ELIXIR_VERSION='1.13.3'

ENV ERLANG_VERSION=$ERLANG_VERSION
ENV ELIXIR_VERSION=$ELIXIR_VERSION
ENV ERLANG_SOURCE=https://erlang.org/download/otp_src_${ERLANG_VERSION}.tar.gz
ENV ELIXIR_SOURCE=https://github.com/elixir-lang/elixir/archive/refs/tags/v${ELIXIR_VERSION}.tar.gz

RUN apt update
RUN apt install -y git locales wget

# elixir não gosta de ser buildado em latin1
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# instalando o C
RUN apt install -y build-essential

# erlang dependencies
RUN apt install -y libncurses5 ncurses-dev

RUN mkdir /tmp/fython-runtimer /tmp/fython-runtimer/erlang /tmp/fython-runtimer/elixir

WORKDIR /tmp/fython-runtimer/erlang
RUN wget $ERLANG_SOURCE && tar -zxf otp_src_$ERLANG_VERSION.tar.gz

RUN apt install -y libssl-dev

WORKDIR /tmp/fython-runtimer/erlang/otp_src_$ERLANG_VERSION
ENV ERL_TOP=/tmp/fython-runtimer/erlang/otp_src_$ERLANG_VERSION
ENV LANG=C
# TODO talvez dê para só copiar parte da pasta do erlang para fazer funcioanr
# TODO assim reduzimos o tamanho

RUN ./configure --prefix=/tmp/fython-runtimer/erlang && make && make install

ENV PATH=/tmp/fython-runtimer/erlang/lib/erlang/bin:$PATH

# elixir
WORKDIR /tmp/fython-runtimer/elixir
RUN wget $ELIXIR_SOURCE && tar -zxf v$ELIXIR_VERSION.tar.gz
RUN cd elixir-$ELIXIR_VERSION && make clean test
RUN mv /tmp/fython-runtimer/elixir /tmp/elixir-full
RUN cp -r /tmp/elixir-full/elixir-1.13.3/lib/elixir/ebin /tmp/fython-runtimer/elixir

## compressing fython ambiente
RUN cd /tmp && \
    tar -czf fython-runtimer.tar.gz fython-runtimer && \
    mv fython-runtimer.tar.gz /fython-runtimer.tar.gz

## install go
RUN apt install -y golang-go

COPY main.go main.go
COPY fython.go fython.go
COPY go.mod go.mod

RUN go run main.go /fython-runtimer.tar.gz fython_com_ambiente.go
RUN CGO_ENABLED=0 go build -i -o fython fython_com_ambiente.go && \
    mv fython /fython