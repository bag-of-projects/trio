#!/bin/bash

set -ex

if [ "$TRAVIS_OS_NAME" = "osx" ]; then
    curl -o macpython.pkg https://www.python.org/ftp/python/${MACPYTHON}/python-${MACPYTHON}-macosx10.6.pkg
    sudo installer -pkg macpython.pkg -target /
    ls /Library/Frameworks/Python.framework/Versions/*/bin/
    if expr "${MACPYTHON}" : 2; then
        PYBASE=python
    else
        PYBASE=python3
    fi
    PYTHON_EXE=/Library/Frameworks/Python.framework/Versions/*/bin/${PYBASE}
    sudo $PYTHON_EXE -m pip install virtualenv
    $PYTHON_EXE -m virtualenv testenv
    source testenv/bin/activate
fi

if [ "$USE_PYPY_NIGHTLY" = "1" ]; then
    curl -o pypy.tar.bz2 http://buildbot.pypy.org/nightly/py3.5/pypy-c-jit-latest-linux64.tar.bz2
    tar xaf pypy.tar.bz2
    # something like "pypy-c-jit-89963-748aa3022295-linux64"
    PYPY_DIR=$(echo pypy-c-jit-*)
    PYTHON_EXE=$PYPY_DIR/bin/pypy3
    $PYTHON_EXE -m ensurepip
    $PYTHON_EXE -m pip install virtualenv
    $PYTHON_EXE -m virtualenv testenv
    source testenv/bin/activate
fi

pip install -U pip setuptools wheel

python setup.py sdist --formats=zip
pip install dist/*.zip

if [ "$DOC_BUILD" = "1" ]; then
    pip install -U sphinx sphinx_rtd_theme
    cd docs
    # -n (nit-picky): warn on missing references
    # -W: turn warnings into errors
    sphinx-build -nW  -b html source build
else
    # Actual tests
    pip install -Ur test-requirements.txt

    mkdir empty
    cd empty

    INSTALLDIR=$(python -c "import os, trio; print(os.path.dirname(trio.__file__))")
    pytest -ra --run-slow ${INSTALLDIR} --cov="$INSTALLDIR" --cov-config=../.coveragerc

    coverage combine
    pip install codecov && codecov
fi
