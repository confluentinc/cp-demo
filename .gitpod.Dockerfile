FROM gitpod/workspace-base:latest

USER root

### Java ###
## Place '.gradle' and 'm2-repository' in /workspace because (1) that's a fast volume, (2) it survives workspace-restarts and (3) it can be warmed-up by pre-builds.
LABEL dazzle/layer=lang-java
LABEL dazzle/test=tests/lang-java.yaml
USER gitpod
RUN curl -fsSL "https://get.sdkman.io" | bash \
    && bash -c ". /home/gitpod/.sdkman/bin/sdkman-init.sh \
    && sdk install java 11.0.12.fx-zulu \
    && sdk install gradle \
    && sdk install maven \
    && sdk flush archives \
    && sdk flush temp \
    && mkdir /home/gitpod/.m2 \
    && printf '<settings>\n  <localRepository>/workspace/m2-repository/</localRepository>\n</settings>\n' > /home/gitpod/.m2/settings.xml \
    && echo 'export SDKMAN_DIR=\"/home/gitpod/.sdkman\"' >> /home/gitpod/.bashrc.d/99-java \
    && echo '[[ -s \"/home/gitpod/.sdkman/bin/sdkman-init.sh\" ]] && source \"/home/gitpod/.sdkman/bin/sdkman-init.sh\"' >> /home/gitpod/.bashrc.d/99-java"
# above, we are adding the sdkman init to .bashrc (executing sdkman-init.sh does that), because one is executed on interactive shells, the other for non-interactive shells (e.g. plugin-host)
ENV GRADLE_USER_HOME=/workspace/.gradle/

### Docker ###
ENV TRIGGER_REBUILD=4
# https://docs.docker.com/engine/install/ubuntu/
RUN curl -o /var/lib/apt/dazzle-marks/docker.gpg -fsSL https://download.docker.com/linux/ubuntu/gpg \
    && apt-key add /var/lib/apt/dazzle-marks/docker.gpg \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && install-packages docker-ce docker-ce-cli containerd.io

RUN curl -o /usr/bin/slirp4netns -fsSL https://github.com/rootless-containers/slirp4netns/releases/download/v1.1.12/slirp4netns-$(uname -m) \
    && chmod +x /usr/bin/slirp4netns

RUN curl -o /usr/local/bin/docker-compose -fsSL https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64 \
    && chmod +x /usr/local/bin/docker-compose

# share env see https://github.com/gitpod-io/workspace-images/issues/472
RUN echo "PATH="${PATH}"" | sudo tee /etc/environment

USER gitpod