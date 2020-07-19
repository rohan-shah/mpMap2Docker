FROM ubuntu:20.04

USER root

ENV DEBIAN_FRONTEND noninteractive
COPY packages.txt .

RUN apt-get update \
 && apt-get install -y gnupg \
 && echo deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ >> /etc/apt/sources.list \
 && gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
 && gpg -a --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | apt-key add - \
 && apt-get install -y ca-certificates \
 && apt-get update && apt-get -yq dist-upgrade

RUN cat packages.txt | xargs apt-get install -y --no-install-recommends \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY Rpackages.txt .
RUN R -e "packages <- read.table('./Rpackages.txt', stringsAsFactors=FALSE); install.packages(packages[,1]);"

RUN R -e "if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); BiocManager::install('Heatplus');"

RUN git clone https://github.com/rohan-shah/Rcpp.git \
 && cd Rcpp \
 && mkdir build \
 && cd build \
 && cmake -DCMAKE_BUILD_TYPE=Release .. \
 && make

RUN git clone https://github.com/rohan-shah/mpMap2.git \
 && cd mpMap2 \ 
 && mkdir build \
 && cd build \ 
 && cmake -DCMAKE_BUILD_TYPE=Release .. -DRcpp_DIR=/Rcpp/build -DUSE_BOOST=On \
 && touch NAMESPACE && make && make install

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.10.0/tini \
 && echo "1361527f39190a7338a0b434bd8c88ff7233ce7b9a4876f3315c22fce7eca1b0 *tini" | sha256sum -c - \
 && mv tini /usr/local/bin/tini \
 && chmod +x /usr/local/bin/tini

# Configure container startup
ENTRYPOINT ["tini", "--"]

# Overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]
