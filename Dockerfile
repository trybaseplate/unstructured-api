# syntax=docker/dockerfile:experimental
FROM quay.io/unstructured-io/base-images:rocky9.2-8@sha256:68b11677eab35ea702cfa682202ddae33f2053ea16c14c951120781a2dcac1b2 as base

# NOTE(crag): NB_USER ARG for mybinder.org compat:
#             https://mybinder.readthedocs.io/en/latest/tutorials/dockerfile.html
ARG NB_USER=notebook-user
ARG NB_UID=1000
ARG PIP_VERSION=21.3.1
ARG PIPELINE_PACKAGE

# Set up environment
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}

RUN groupadd --gid ${NB_UID} ${NB_USER}
RUN useradd --uid ${NB_UID} --gid ${NB_UID} ${NB_USER}
WORKDIR ${HOME}

ENV PYTHONPATH="${PYTHONPATH}:${HOME}"
ENV PATH="/home/${NB_USER}/.local/bin:${PATH}"

FROM base as python-deps
# COPY requirements/dev.txt requirements-dev.txt
COPY ./requirements-base.txt requirements-base.txt
RUN python3.10 -m pip install pip==23.3.1 \
  && dnf -y groupinstall "Development Tools" \
  && su -l ${NB_USER} -c 'pip3.10 install  --no-cache  -r antlr4-python3-runtime==4.9.3 anyio==3.7.1 backoff==2.2.1 beautifulsoup4==4.12.2 certifi==2023.7.22 cffi==1.16.0 chardet==5.2.0 charset-normalizer==3.3.2 click==8.1.3 coloredlogs==15.0.1 contourpy==1.2.0 cryptography==41.0.5 cycler==0.12.1 dataclasses-json==0.6.1 effdet==0.4.1 emoji==2.8.0 et-xmlfile==1.1.0 fastapi==0.104.1 filelock==3.13.1 filetype==1.2.0 flatbuffers==23.5.26 fonttools==4.44.0 fsspec==2023.10.0 h11==0.14.0 huggingface-hub==0.17.3 humanfriendly==10.0 idna==3.4 iopath==0.1.10 jinja2==3.1.2 joblib==1.3.2 kiwisolver==1.4.5 langdetect==1.0.9 layoutparser[layoutmodels,tesseract]==0.3.4 lxml==4.9.3 markdown==3.5.1 markupsafe==2.1.3 marshmallow==3.20.1 matplotlib==3.8.1 mpmath==1.3.0 msg-parser==1.2.0 mypy-extensions==1.0.0 networkx==3.2.1 nltk==3.8.1 numpy==1.26.1 olefile==0.46 omegaconf==2.3.0 onnx==1.15.0 onnxruntime==1.15.1 opencv-python==4.8.1.78 openpyxl==3.1.2 packaging==23.2 pandas==2.1.2 pdf2image==1.16.3 pdfminer-six==20221105 pdfplumber==0.10.3 pillow==10.1.0 portalocker==2.8.2 protobuf==4.25.0 psutil==5.9.6 pycocotools==2.0.7 pycparser==2.21 pycryptodome==3.19.0 pydantic==1.10.13 pypandoc==1.12 pyparsing==3.1.1 pypdf==3.17.0 pypdfium2==4.23.1 pytesseract==0.3.10 python-dateutil==2.8.2 python-docx==1.1.0 python-iso639==2023.6.15 python-magic==0.4.27 python-multipart==0.0.6 python-pptx==0.6.21 pytz==2023.3.post1 pyyaml==6.0.1 rapidfuzz==3.5.2 ratelimit==2.2.1 regex==2023.10.3 requests==2.31.0 safetensors==0.3.2 scipy==1.11.3 six==1.16.0 sniffio==1.3.0 soupsieve==2.5 starlette==0.27.0 sympy==1.12 tabulate==0.9.0 timm==0.9.10 tokenizers==0.14.1 torch==2.1.0 torchvision==0.16.0 tqdm==4.66.1 transformers==4.35.0 typing-extensions==4.8.0 typing-inspect==0.9.0 tzdata==2023.3 unstructured[local-inference]==0.10.29 unstructured-inference==0.7.11 unstructured-pytesseract==0.3.12 urllib3==2.0.7 uvicorn==0.24.0.post1 xlrd==2.0.1 xlsxwriter==3.1.9' \
  && dnf -y groupremove "Development Tools" \
  && dnf clean all \
  && ln -s /home/notebook-user/.local/bin/pip3.10 /usr/local/bin/pip3.10 || true

USER ${NB_USER}

FROM python-deps as model-deps

RUN python3.10 -c "import nltk; nltk.download('punkt')" && \
  python3.10 -c "import nltk; nltk.download('averaged_perceptron_tagger')" && \
  python3.10 -c "from unstructured.ingest.pipeline.initialize import initialize; initialize()"

FROM model-deps as code
COPY --chown=${NB_USER}:${NB_USER} CHANGELOG.md CHANGELOG.md
COPY --chown=${NB_USER}:${NB_USER} logger_config.yaml logger_config.yaml
COPY --chown=${NB_USER}:${NB_USER} prepline_${PIPELINE_PACKAGE}/ prepline_${PIPELINE_PACKAGE}/
COPY --chown=${NB_USER}:${NB_USER} exploration-notebooks exploration-notebooks
COPY --chown=${NB_USER}:${NB_USER} scripts/app-start.sh scripts/app-start.sh

ENTRYPOINT ["scripts/app-start.sh"]
# Expose a default port of 8000. Note: The EXPOSE instruction does not actually publish the port,
# but some tooling will inspect containers and perform work contingent on networking support declared.
EXPOSE 8000
