#! /bin/bash -eu

export DEBIAN_FRONTEND=noninteractive
export VENV_DIR=${VENV_DIR:-"/opt/venv"}
export VENV_NAME=${VENV_NAME:-"dev"}

help() {
    echo "Invalid Usage" > /dev/stderr
    echo "Usage: $0 [standard | conda]" > /dev/stderr
    exit 1
}

standard() {

cat > deadsnake.pgp << FILE
-----BEGIN PGP PUBLIC KEY BLOCK-----
Comment: Hostname: 
Version: Hockeypuck 2.1.0-222-g25248d4

xsFNBFl8fYEBEADQmGZ6pDrwY9iH9DVlwNwTOvOZ7q7lHXPl/TLfMs1tckMc/D9a
hsdBN9VWtMmo+RySvhkIe8X15r65TFs2HE8ft6j2e/4K472pObM1hB+ajiU/wYX2
Syq7DBlNm6YMP5/SyQzRxqis4Ja1uUjW4Q5/Csdf5In8uMzXj5D1P7qOiP2aNa0E
r3w6PXWRTuTihWZOsHv8npyVYDBRR6gEZbd3r86snI/7o8Bfmad3KjbxL7aOdNMw
AqQFaNKl7Y+UJpv1CNFIf+twcOoC0se1SrsVJlAH9HNHM7XGQsPUwpNvQlcmvr+t
1vVS2m72lk3gyShDuJpi1TifGw+DoTqu54U0k+0sZm4pnQVeiizNkefU2UqOoGlt
4oiG9nIhSX04xRlGes3Ya0OjNI5b1xbcYoR+r0c3odI+UCw3VSZtKDX/xlH1o/82
b8ouXeE7LA1i4DvGNj4VSvoxv4ggIznxMf+PkWXWKwRGsbAAXF52rr4FUaeaKoIU
DkJqHXAxrB3PQslZ+ZgBEukkQZF76NkqRqP1E7FXzZZMo2eEL7vtnhSzUlanOf42
ECBoWHVoZQaRFMNbGpqlg9aWedHGyetMStS3nH1sqanr+i4I8VR/UH+ilarPTW3T
E0apWlsH8+N3IKbRx2wgrRZNoQEuyVtvyewDFYShJB3Zxt7VCy67vKAl1QARAQAB
zRxMYXVuY2hwYWQgUFBBIGZvciBkZWFkc25ha2VzwsF4BBMBAgAiBQJZfH2BAhsD
BgsJCAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRC6aTI2anVXdvwhD/4oI3yckeKn
9aJNNTJsyw4ydMkIAOdG+jbZsYv/rN73UVQF1RA8HC71SDmbd0Nu80koBOX+USuL
vvhoMIsARlD5dLx5f/zaQcYWJm/BtsMF/eZ4s1xsenwW6PpXd8FpaTn1qtg/8+O9
99R4uSetAhhyf1vSRb/8U0sgSQd38mpZZFq352UuVisXnmCThj621loQubYJ3lwU
LSLs8wmgo4XIYH7UgdavV9dfplPh0M19RHQL3wTyQP2KRNRq1rG7/n1XzUwDyqY6
eMVhdVhvnxAGztvdFCySVzBRr/rCw6quhcYQwBqdqaXhz63np+4mlUNfd8Eu+Vas
b/tbteF/pDu0yeFMpK4X09Cwn2kYYCpq4XujijW+iRWb4MO3G8LLi8oBAHP/k0CM
/QvSRbbG8JDQkQDH37Efm8iE/EttJTixjKAIfyugmvEHfcrnxaMoBioa6h6McQrM
vI8bJirxorJzOVF4kY7xXvMYwjzaDC8G0fTA8SzQRaShksR3USXZjz8vS6tZ+YNa
mRHPoZ3Ua0bz4t2aCcu/fknVGsXcNBazNIK9WF2665Ut/b7lDbojXsUZ3PpuqOoe
GQL9LRj7nmCI6ugoKkNp8ZXcGJ8BGw37Wep2ztyzDohXp6f/4mGgy2KYV9R4S8D5
yBDUU6BS7Su5nhQMStfdfr4FffLmnvFC9w==
=s7P2
-----END PGP PUBLIC KEY BLOCK-----
FILE

echo "Adding Deadsnake Key & Repository..."
(curl -fsL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xf23c5a6cf475977595c89f51ba6932366a755776" \
    || cat deadsnake.pgp) | gpg --dearmor -o /usr/share/keyrings/deadsnake-python.gpg

cat > /etc/apt/sources.list.d/deadsnake-python.list << FILE
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/deadsnake-python.gpg] https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu focal main
deb-src [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/deadsnake-python.gpg] https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu focal main
FILE

if [[ "$PYTHON_VERSION" == 3.*.* ]]; then
    export PYTHON_VERSION=${PYTHON_VERSION%.*}
elif [[ "$PYTHON_VERSION" == 3.* ]]; then
    export PYTHON_VERSION=${PYTHON_VERSION}
else 
    echo "Invalid Python Version..." > /dev/stderr
    echo "Version Must be 3.X or 3.X.X" > /dev/stderr
    exit 1
fi

# - `python#.#-dev`: includes development headers for building C extensions
# - `python#.#-venv`: provides the standard library `venv` module
# - `python#.#-distutils`: provides the standard library `distutils` module
# - `python#.#-lib2to3`: provides the `2to3-#.#` utility as well as the standard library `lib2to3` module
# - `python#.#-gdbm`: provides the standard library `dbm.gnu` module
# - `python#.#-tk`: provides the standard library `tkinter` module

apt-get update
apt-get install -q --yes --no-install-recommends \
    python3-virtualenv \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-venv \
    python${PYTHON_VERSION}-distutils \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-lib2to3 \
    python${PYTHON_VERSION}-gdbm \
    build-essential

export PIP_URL=$([[ "${PYTHON_VERSION}" < "3.7" ]] && echo "https://bootstrap.pypa.io/pip/${PYTHON_VERSION}/get-pip.py"  || echo "https://bootstrap.pypa.io/get-pip.py")
wget -q ${PIP_URL}
python${PYTHON_VERSION} get-pip.py
virtualenv --copies --download --python python${PYTHON_VERSION} ${VENV_DIR}/${VENV_NAME}

python${PYTHON_VERSION} -m pip install -U --no-cache-dir wheel setuptools

# rm -rf /var/cache/apt/* /var/lib/apt/*

}

miniconda() {
export MINIFORGE_ARCH="x86_64"
export MINIFORGE_VERSION="23.3.1-0"
export PYTHON_VERSION=${PYTHON_VERSION}
export CONDA_DIR=${CONDA_DIR:-"/opt/conda"}

mkdir -p ${CONDA_DIR} ${VENV_DIR}
chown -R $(id -u):$(id -g) ${CONDA_DIR} ${VENV_DIR}

curl -fsL "https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Mambaforge-${MINIFORGE_VERSION}-Linux-${MINIFORGE_ARCH}.sh" -o /tmp/Miniforge3.sh
curl -fsL "https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Mambaforge-${MINIFORGE_VERSION}-Linux-${MINIFORGE_ARCH}.sh.sha256" -o /tmp/Miniforge3.sh.sha256

echo "$(cat /tmp/Miniforge3.sh.sha256 | awk '{ print $1; }') /tmp/Miniforge3.sh" | sha256sum --check
rm /tmp/Miniforge3.sh.sha256

/bin/bash /tmp/Miniforge3.sh -b -f -p ${CONDA_DIR} 
rm /tmp/Miniforge3.sh

export PATH="${CONDA_DIR}/bin:${PATH}"

conda config --system --set auto_update_conda false 
conda config --system --set show_channel_urls true 
conda config --system --prepend envs_dirs ${VENV_DIR}
conda config --system --add create_default_packages ipykernel

echo "conda ${MINIFORGE_VERSION:0:-2}" > ${CONDA_DIR}/conda-meta/pinned 
echo "python ${PYTHON_VERSION}" > ${CONDA_DIR}/conda-meta/pinned 

conda create -yq -p ${VENV_DIR}/${VENV_NAME} \
    python=${PYTHON_VERSION}

conda update -y -q --all 
conda clean -a -f -y 

# rm -rf /var/cache/apt/* /var/lib/apt/*
}

if [[ "x$#" != "x1" ]]; then
    help
elif [[ "x$1" == "xstandard" ]]; then 
    echo "Installing Python in Standard Way: "
    standard
    exit 0
elif [[ "x$1" == "xconda" ]]; then
    echo "Installing Python with Conda (conda-forge)"
    miniconda
    exit 0
else 
    help
fi