FROM europe-west9-docker.pkg.dev/cloud-workstations-images/predefined/base:latest

RUN apt-get update --yes && \
    # - apt-get upgrade is run to patch known vulnerabilities in apt-get packages as
    #   the ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    # - bzip2 is necessary to extract the micromamba executable.
    bzip2 \
    ca-certificates \
    locales \
    sudo \
    # - tini is installed as a helpful container entrypoint that reaps zombie
    #   processes and such of the actual executable we want to start, see
    #   https://github.com/krallin/tini#why-tini for details.
    tini \
    fonts-liberation \
    # - pandoc is used to convert notebooks to html files
    #   it's not present in aarch64 ubuntu image, so we install it here
    pandoc \
    # - run-one - a wrapper script that runs no more
    #   than one unique  instance  of  some  command with a unique set of arguments,
    #   we use `run-one-constantly` to support `RESTARTABLE` option
    run-one \
    wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

ENV CONDA_DIR=/opt/conda \
SHELL=/bin/bash \
LC_ALL=en_US.UTF-8 \
LANG=en_US.UTF-8 \
LANGUAGE=en_US.UTF-8 \
PATH="${CONDA_DIR}/bin:${PATH}" \
PYTHON_VERSION=3.11

COPY initial-condarc "${CONDA_DIR}/.condarc"

RUN set -x && cd /tmp && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        # Should be simpler, see <https://github.com/mamba-org/mamba/issues/1437>
        arch="64"; \
    fi && \
    wget --progress=dot:giga -O /tmp/micromamba.tar.bz2 \
        "https://micromamba.snakepit.net/api/micromamba/linux-${arch}/latest" && \
    tar -xvjf /tmp/micromamba.tar.bz2 --strip-components=1 bin/micromamba && \
    rm /tmp/micromamba.tar.bz2 && \
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" && \
    if [[ "${PYTHON_VERSION}" == "default" ]]; then PYTHON_SPECIFIER="python"; fi && \
    # Install the packages
    ./micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        "${PYTHON_SPECIFIER}" \
        'mamba' \
        'jupyter_core' \
        'jupyterlab' \
        'notebook' \
        'jupyterhub' \
         'nbclassic' && \
    rm micromamba

RUN mkdir -p /usr/local/bin/start-notebook.d && \
    mkdir -p /usr/local/bin/before-notebook.d

RUN echo "export PATH=${CONDA_DIR}/bin:${PATH}" >> /etc/bash.bashrc

COPY 110_start-jupyter.sh /etc/workstation-startup.d/110_start-jupyter.sh
COPY run-hooks.sh start.sh /usr/local/bin/

ENV JUPYTER_PORT=80
EXPOSE $JUPYTER_PORT

# Copy local files as late as possible to avoid cache busting
COPY start-notebook.sh start-singleuser.sh /usr/local/bin/
COPY jupyter_server_config.py docker_healthcheck.py /etc/jupyter/

ENV PATH="${CONDA_DIR}/bin:${PATH}" 

WORKDIR "${HOME}"
