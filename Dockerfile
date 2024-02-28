FROM public.ecr.aws/lambda/provided:al2023

ARG GHCUP_DWN_URL=https://downloads.haskell.org/~ghcup/x86_64-linux-ghcup
ARG VERSION_GHC=9.4.8
ARG VERSION_CABAL=latest
ARG VERSION_STACK=latest

ARG USER_NAME=haskell
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# curl-minimal is too restrictive for data integration
RUN  \
    dnf install --assumeyes libssh libpsl libbrotli \
    && dnf download curl libcurl \
    && rpm -Uvh --nodeps --replacefiles "*curl*$( uname -i ).rpm" \
    && dnf remove -y libcurl-minimal curl-minimal

RUN \
    dnf install --assumeyes findutils \
        cmake \
        gcc \
        g++ \
        gmp-devel \
        gmp-static \
        glibc-static \
        zlib-devel \
        zlib-static \
        vim \
        sudo \
        jq \
        git

RUN \
    /usr/bin/curl ${GHCUP_DWN_URL} > /usr/bin/ghcup && \
    chmod +x /usr/bin/ghcup

# creating the workspace user
RUN /usr/sbin/groupadd --gid ${USER_GID} ${USER_NAME} \
    && /usr/sbin/useradd --uid ${USER_UID} --gid ${USER_GID} --no-log-init --create-home -m ${USER_NAME} -s /usr/bin/bash \
    && /bin/echo ${USER_NAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USER_NAME} \
    && chmod 0440 /etc/sudoers.d/${USER_NAME}

USER ${USER_NAME}

WORKDIR /home/${USER_NAME}

RUN /usr/bin/curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" --output "awscliv2.zip" \
    && unzip awscliv2.zip \
    && sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update \
    && rm -fr awscliv2.zip \
    && rm -fr ./aws

RUN /usr/bin/curl "https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip" --output "/tmp/terraform.zip" \
    && mkdir -p  /home/${USER_NAME}/.local/bin \
    && unzip /tmp/terraform.zip -d /home/${USER_NAME}/.local/bin \
    && chmod 755 /home/${USER_NAME}/.local/bin/terraform \
    && rm -f /tmp/terraform.zip

# installing GHC, cabal and stack (better not use stack though)
RUN \
    ghcup -v install ghc --force ${VERSION_GHC} && \
    ghcup -v install cabal --force ${VERSION_CABAL} && \
    ghcup -v install stack --force ${VERSION_STACK} && \
    ghcup set ghc ${VERSION_GHC} && \
    ghcup install hls

RUN /bin/echo -e "\nexport PATH=$PATH:/home/${USER_NAME}/.ghcup/bin:/home/${USER_NAME}/.local/bin/\n" >> /home/${USER_NAME}/.bashrc

SHELL ["/usr/bin/bash", "--login", "-i", "-c"]

CMD [ "sleep", "infinity" ]
