# docker build -t resolver .
# docker run --rm -i -v `pwd`:/home/opam/src resolver

# Pin the base image to a specific hash for maximum reproducibility.
# It will probably still work on newer images, though, unless an update
# changes some compiler optimisations (unlikely).
# bookworm-slim
# https://hub.docker.com/_/debian/tags?page=1&name=bookworm-slim
FROM debian@sha256:a60c0c42bc6bdc09d91cd57067fcc952b68ad62de651c4cf939c27c9f007d1c5

# and set the package source to a specific release too (notset.fr is down nowadays :/ )
#RUN printf "deb [check-valid-until=no] http://snapshot.notset.fr/archive/debian/20230418T024659Z bookworm main" > /etc/apt/sources.list

RUN apt update && apt install --no-install-recommends --no-install-suggests -y wget ca-certificates git patch unzip bzip2 xz-utils make gcc g++ libc-dev
RUN wget -O /usr/bin/opam https://github.com/ocaml/opam/releases/download/2.1.5/opam-2.1.5-i686-linux && chmod 755 /usr/bin/opam

ENV OPAMROOT=/tmp
ENV OPAMCONFIRMLEVEL=unsafe-yes

# Pin last known-good version for reproducible builds.
# Remove this line (and the base image pin above) if you want to test with the
# latest versions.
RUN opam init --disable-sandboxing -a --bare https://github.com/ocaml/opam-repository.git#f3720b1ca1ef3a1ee1b233bc11252abe46b6e4be
RUN opam switch create myswitch 4.14.1
RUN opam exec -- opam install -y mirage opam-monorepo ocaml-solo5

WORKDIR /home/opam/src
CMD opam exec -- sh -exc 'mirage configure -t unix && make depend && dune build'
