FROM satapps/dask-datacube:v3.1.1-alpha as BaseStage
LABEL maintainer="Emily Selwood <emily.selwood@sa.catapult.org.uk>"

COPY . /app/
WORKDIR /app/

RUN apt-get update \
    && apt-get install -yq --no-install-recommends \
    git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir --extra-index-url="https://packages.dea.ga.gov.au" -r requirements.txt

RUN conda install --yes \
    -c conda-forge \
    geopandas \
    hdmedians \
    && conda clean -tipsy \
    && find /opt/conda/ -type f,l -name '*.a' -delete \
    && find /opt/conda/ -type f,l -name '*.pyc' -delete \
    && find /opt/conda/ -type f,l -name '*.js.map' -delete \
    && rm -rf /opt/conda/pkgs

RUN groupadd -g 999 celery && \
    useradd -r -u 999 -g celery celery

RUN mkdir /cubequery-repo && chown -R celery:celery /cubequery-repo && chmod 777 -R /cubequery-repo
USER celery:celery

CMD ["python", "-m", "celery", "worker", "-E", "-A", "cubequery.api_server.celery_app", "--loglevel", "DEBUG"]
