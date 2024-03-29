FROM ubuntu:20.04

#Prerequisites
RUN apt update && apt upgrade -y && \
    apt install --no-install-recommends sudo curl apt-utils ca-certificates nginx systemd -y && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Setup users and permissions
RUN adduser --disabled-password --gecos "" general && \
    usermod -aG sudo general && \ 
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER general

#Install Node v16
RUN curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
RUN sudo apt update && sudo apt upgrade -y && sudo apt install -y nodejs

#Configure Ghost
ENV NODE_ENV production
ENV GHOST_VERSION 4.48.8
ENV GHOST_CLI_VERSION 1.19.3
ENV GHOST_DIR /var/lib/ghost
ENV GHOST_CONTENT_DIR /var/lib/ghost/content

#Install Ghost CLI
RUN sudo mkdir -p "${GHOST_DIR}" && \
    sudo chown general:general "${GHOST_DIR}" && \
    sudo chmod 775 "${GHOST_DIR}" && \
#    sudo mkdir -p "${GHOST_CONTENT_DIR}" && \
#    sudo chown general:general "${GHOST_CONTENT_DIR}" && \
#    sudo chmod 777 "${GHOST_CONTENT_DIR}" && \
    sudo npm install -g "ghost-cli@${GHOST_CLI_VERSION}"

#Install Ghost
WORKDIR "${GHOST_DIR}"
RUN ghost install "${GHOST_VERSION}" --db sqlite3 --no-stack --no-prompt --no-start --no-setup
RUN ghost config --ip '::' --port 2368 --no-prompt --db sqlite3 --url http://localhost:2368 --dbpath "${GHOST_CONTENT_DIR}/data/ghost.db"
RUN ghost config paths.contentPath "${GHOST_CONTENT_DIR}"

# Permission fix content
RUN sudo mkdir -p "${GHOST_CONTENT_DIR}" && \
    sudo chown general:general "${GHOST_CONTENT_DIR}" && \
    sudo chmod 777 "${GHOST_CONTENT_DIR}"

#Install Ghost Storage Adapter
RUN npm install ghost-storage-adapter-s3 && \
    mkdir -p "${GHOST_CONTENT_DIR}/adapters/storage" && \
    cp -r ./node_modules/ghost-storage-adapter-s3 "${GHOST_CONTENT_DIR}/adapters/storage/s3"

#Install 3rd Party Themes
COPY ./content/themes/ "${GHOST_CONTENT_DIR}/themes/"

#Entrypoint
ENTRYPOINT [ "node", "current/index.js" ]