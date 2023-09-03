IMAGE_TYPE?= gpu # cpu or gpu
CUDA_VERSION?= 12.0.0
PYTHON_VERSION?= 3.8
IMAGE_TAG?= test-image:v1.0

build-dev: kubeflow/*
	DOCKER_BUILDKIT=1 docker build -t ${IMAGE_TAG} --target vscode-jupyter-kubeflow --build-arg IMAGE_TYPE=${IMAGE_TYPE} --build-arg CUDA_VERSION=${CUDA_VERSION} --build-arg PYTHON_VERSION=${PYTHON_VERSION} -f kubeflow/Dockerfile .

build-prod: python/*
	DOCKER_BUILDKIT=1 docker build -t ${IMAGE_TAG} --target python-image --build-arg IMAGE_TYPE=${IMAGE_TYPE} --build-arg CUDA_VERSION=${CUDA_VERSION} --build-arg PYTHON_VERSION=${PYTHON_VERSION} -f python/Dockerfile .