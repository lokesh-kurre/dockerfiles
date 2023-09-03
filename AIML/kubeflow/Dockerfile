ARG IMAGE_TYPE=gpu
ARG CUDA_VERSION=12.0.0
ARG PYTHON_VERSION=3.8.0
ARG PIP_ROOT_USER_ACTION=ignore

# -------------------------------------- BASE IMAGE (CPU) ----------------------------------------------
FROM --platform=linux/amd64 ubuntu:20.04 as base-ubuntu-image-cpu

# -------------------------------------- BASE IMAGE (GPU) ----------------------------------------------
FROM --platform=linux/amd64 nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu20.04 AS base-ubuntu-image-gpu

ARG CUDA_VERSION

ENV CUDA_VERSION=${CUDA_VERSION}

# ---------------------------------- BASE PYTHON (CONDA) IMAGE -----------------------------------------
FROM base-ubuntu-image-${IMAGE_TYPE} AS conda-python

ARG PYTHON_VERSION
ARG PIP_ROOT_USER_ACTION

ENV TZ="Asia/Kolkata" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"

COPY setup-basic.sh /setup-basic.sh

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=apt.conf,target=/etc/apt/apt.conf \
    chmod +x setup-basic.sh \
    && /setup-basic.sh

ENV PYTHON_VERSION=${PYTHON_VERSION} \
    CONDA_DIR="/opt/conda" \
    PATH="${CONDA_DIR}/condabin:${CONDA_DIR}/bin:${PATH}" \
    VENV_DIR="/opt/venv" \
    VENV_NAME="dev"

COPY setup-python.sh /setup-python.sh

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=apt.conf,target=/etc/apt/apt.conf \
    chmod +x setup-python.sh \
    && /setup-python.sh conda

ENV PATH="${VENV_DIR}/${VENV_NAME}/bin:${PATH}"

ENTRYPOINT [ "tini", "--" ]

CMD "/bin/bash"


# ---------------------------------- BASE PYTHON (CONDA) IMAGE -----------------------------------------
FROM conda-python AS vscode-jupyter-kubeflow

ENV CODESERVER_VERSION=v4.16.0 
# Code v1.80.1

COPY kubeflow/setup-kubeflow.sh /setup-kubeflow.sh

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=apt.conf,target=/etc/apt/apt.conf \
    chmod +x /setup-kubeflow.sh \
    && /setup-kubeflow.sh
    

COPY kubeflow/requirements.txt /requirements.txt
RUN python3 -m pip install --no-cache-dir -r requirements.txt

COPY kubeflow/entrypoint.sh /entrypoint.sh
RUN chmod +x "/entrypoint.sh"

CMD "/entrypoint.sh"