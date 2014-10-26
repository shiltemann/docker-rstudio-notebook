FROM debian:squeeze
# Must use older version for libssl0.9.8
MAINTAINER Eric Rasche <rasche.eric@yandex.ru>

ENV DEBIAN_FRONTEND noninteractive

# Ensure cran is available
RUN (echo "deb http://cran.mtu.edu/bin/linux/debian squeeze-cran/" >> /etc/apt/sources.list && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9) && \
    (echo "deb-src http://http.debian.net/debian squeeze main" >> /etc/apt/sources.list && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9)

RUN apt-get -qq update --fix-missing && apt-get install --no-install-recommends -y apt-transport-https \
    r-base r-base-dev wget psmisc libssl0.9.8 sudo libcurl4-openssl-dev curl libxml2-dev \
    net-tools nginx dpkg python python-pip && \
    pip install distribute --upgrade && \
    pip install bioblend && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Rstudio
RUN wget http://download2.rstudio.org/rstudio-server-0.98.987-amd64.deb && dpkg -i rstudio-server-0.98.987-amd64.deb && rm /rstudio-server-0.98.987-amd64.deb

COPY ./GalaxyConnector.tar.gz /tmp/GalaxyConnector.tar.gz
# Install packages
ADD ./packages.R /tmp/packages.R
RUN Rscript /tmp/packages.R && rm /tmp/packages.R

# Suicide
ADD ./monitor_traffic.sh /monitor_traffic.sh
RUN chmod +x /monitor_traffic.sh

# /import will be the universal mount-point for IPython
# The Galaxy instance can copy in data that needs to be present to the IPython webserver
RUN mkdir /import
VOLUME ["/import/"]
WORKDIR /import/

ADD ./startup.sh /startup.sh
RUN chmod +x /startup.sh
ADD ./proxy.conf /proxy.conf
ADD ./galaxy.py /usr/local/bin/galaxy.py
RUN chmod +x /usr/local/bin/galaxy.py
ADD ./Rprofile.site /usr/lib/R/etc/Rprofile.site

# Start IPython Notebook
CMD /startup.sh
