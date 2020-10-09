ARG ELECTRS_VERSION=0.4.1
ARG ELECTRS_COMMIT=2f8759e940a3fe56002d653c29a480ed3bffa416                
ARG USER=electrs
ARG UID=1000
ARG GID=1000
ARG DIR=/srv/electrs

FROM rust:1.44.1-slim as BUILD   
                                               
SHELL ["/bin/bash", "-c"]

RUN apt-get -yqq update \                                                                     
 && apt-get -yqq upgrade \                     
 && apt-get -yqq install clang cmake curl git \ 
 && mkdir -p /srv/electrs{_bitcoin,_liquid} \
 && git clone --no-checkout https://github.com/blockstream/electrs.git \
 && cd electrs \
 && git checkout $ELECTRS_COMMIT \
 #&& cp contrib/popular-scripts.txt /srv/electrs_bitcoin \
 && cargo install --root /srv/electrs_bitcoin --locked --path . --features electrum-discovery \
 #&& cargo install --root /srv/electrs_liquid --locked --path . --features electrum-discovery,liquid \
 && cd .. \
 && rm -fr /root/.cargo electrs \
 && strip /srv/electrs_*/bin/electrs \
 && apt-get --auto-remove remove -yqq --purge clang cmake manpages curl git \
 && apt-get clean \
 && apt-get autoclean \
 && rm -rf /usr/share/doc* /usr/share/man /usr/share/postgresql/*/man /var/lib/apt/lists/* /var/cache/* /tmp/* /root/.cache /*.deb /root/.cargo

FROM debian:buster@sha256:46d659005ca1151087efa997f1039ae45a7bf7a2cbbe2d17d3dcbda632a3ee9a

SHELL ["/bin/bash", "-c"]

COPY --from=BUILD /srv/electrs_bitcoin /srv/electrs

RUN adduser --disabled-login --system --shell /bin/false --home /srv/electrs --uid $UID --gid $GID $USER
USER $USER
WORKDIR $DIR

EXPOSE 50001 3000 4224

STOPSIGNAL SIGINT

#Placeholder
ENTRYPOINT ["/bin/sh"]
