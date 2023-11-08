# syntax=docker/dockerfile:1.2
ARG SRCVERSION=17
ARG SRCTAG=2022-01-17
ARG SRCHUBID=dataeditors
ARG RVERSION=4.1.0
ARG RTYPE=verse
ARG CONDATYPE=anaconda3
ARG CONDAVER=2021.11

# define the source for Stata
FROM ${SRCHUBID}/stata${SRCVERSION}:${SRCTAG} as stata

# define the source for python/conda

FROM continuumio/${CONDATYPE}:${CONDAVER} as conda

# use the source for R

FROM rocker/${RTYPE}:${RVERSION}
COPY --from=stata /usr/local/stata/ /usr/local/stata/
RUN echo "export PATH=/usr/local/stata:${PATH}" >> /root/.bashrc
ENV PATH "$PATH:/usr/local/stata" 

# copy the license in so we can do the install of packages
USER root
RUN --mount=type=secret,id=statalic \
    cp /run/secrets/statalic /usr/local/stata/stata.lic \
    && chmod a+r /usr/local/stata/stata.lic

# Stuff we need from the Stata Docker Image
# https://github.com/AEADataEditor/docker-stata/blob/f2c0d52f133a32c6892fe1f67796322390ce7c35/Dockerfile#L15
# Stuff we need from the anaconda3 image
# https://github.com/ContinuumIO/docker-images/blob/76a5a259b25b8493d41def50a38312009c65f2e5/anaconda3/debian/Dockerfile#L10
# We need to redo this here, since we are using the base image from `rocker`. 
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
         locales \
         libncurses5 \
         libfontconfig1 \
         git \
         nano \
         unzip \
         bzip2 \
        ca-certificates \
        git \
        libglib2.0-0 \
        libsm6 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxinerama1 \
        libxrandr2 \
        libxrender1 \
        mercurial \
        openssh-client \
        procps \
        subversion \
        wget \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Copying in the Conda stuff
COPY --from=conda /opt/conda/ /opt/conda/

# Set up the path stuff
RUN \
  ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh 
##======================================
# Install JDK
##======================================
WORKDIR /
RUN \ 
   wget -O jdk.deb https://download.oracle.com/java/18/latest/jdk-18_linux-x64_bin.deb \
   && DEBIAN_FRONTEND=noninteractive apt-get install -y ./jdk.deb \
   && rm jdk.deb \
   && rm -rf /var/lib/apt/lists/* 

# Set a few more things
ENV LANG en_US.utf8

#=============================================== REGULAR USER
# install any packages into the home directory as the user
# NOTE: in contrast to the base Docker image, we are using
# the "normal" user from the `rocker` image, to keep things
# simple

COPY setup /home/rstudio/setup
RUN chmod -R a+rwX /opt/conda
USER rstudio
WORKDIR /home/rstudio

RUN \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    echo "export PATH=/usr/local/stata:\$PATH" >> ~/.bashrc

#============== Project specific install
#RUN \
#    . /opt/conda/etc/profile.d/conda.sh \
#    && conda env create -f setup/conda_env.yaml \
#    && cd setup \
#    && python3 check_setup.py \
#    && Rscript setup_r.r \
#    && /usr/local/stata/stata do setup/download_stata_ado.do | tee setup.$(date +%F).log
#=============================================== Clean up
#  then delete the license again
USER root
RUN rm /usr/local/stata/stata.lic

# Setup for standard operation
USER rstudio
WORKDIR /project
ENTRYPOINT ["/bin/bash"]

