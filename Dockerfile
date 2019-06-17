FROM jenkins/jenkins:latest

LABEL maintainer="pluhin@gmail.com"

ARG DEBIAN_FRONTEND=noninteractive

ENV ICINGA2_VERSION="2.10.4" \
    TIMEZONE="UTC" \
    ICINGA_API_PASS="QwertY_13" \
    ICINGA_LOGLEVEL=warning \
    ICINGA_FEATURES="api" \
	ANSIBLE_VERSION="2.8"

RUN /usr/local/bin/install-plugins.sh ssh-slaves \
	email-ext \
	mailer \
	greenballs \
	simple-theme-plugin \
	parameterized-trigger \
	rebuild \
	github \
	mask-passwords \
	multiple-scms \
	ansicolor \
	blueocean \
	stashNotifier \
	show-build-parameters \
	credentials \
	configuration-as-code-support \
	configuration-as-code \
    slack
USER root

RUN apt-get update && apt-get install -yqq apt-transport-https \
		python-pip \
		sshpass \
		ca-certificates \
		curl \
		gnupg2 \
        wget \
		software-properties-common \
	&& apt-get install -y --no-install-recommends \
      curl \
      dnsutils \
      file \
      gnupg \
      locales \
      wget \
	&& curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey \
    && add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
        $(lsb_release -cs) \
        stable" \
	&& apt-get update \
	&& pip install ansible=="$ANSIBLE_VERSION" -qq \
		awscli \
	&& git config --global core.sshCommand 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' \
	&& apt-get -y install docker-ce -qq \
    && apt-get install rsync -y -qq\
	&& gpasswd -a jenkins docker \
	&& usermod -a -G docker jenkins \
    && newgrp docker \
	&& echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config \
	&& echo "    UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config \
	&& wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 \
    && chmod +x /usr/local/bin/dumb-init \
    && apt-get purge --auto-remove -yqq \
	&& apt-get clean \
	&& rm -rf \
	    /var/lib/apt/lists/* \
	    /tmp/* \
	    /var/tmp/* \
	    /usr/share/man \
	    /usr/share/doc \
	    /usr/share/doc-base

RUN export DEBIAN_FRONTEND=noninteractive \
 && curl -s https://packages.icinga.com/icinga.key \
 | apt-key add - \
 && echo "deb http://packages.icinga.org/debian icinga-$(lsb_release -cs) main" > /etc/apt/sources.list.d/icinga2.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      icinga2-$ICINGA2_VERSION \
      icingacli \
      monitoring-plugins \
      nagios-nrpe-plugin \
      nagios-plugins-contrib \
      nagios-snmp-plugins \
      libmonitoring-plugin-perl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ADD icinga2 /

RUN echo "jenkins	ALL=(ALL)	NOPASSWD: ALL" >> /etc/sudoers \
    && echo "DOCKER_OPTS=' -G jenkins'" >> /etc/default/docker

VOLUME [ "/var/lib/icinga2", "/etc/icinga2", "/tmp" ]

#USER jenkins
CMD ["/init/run.sh"]