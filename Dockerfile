FROM docker.io/library/julia:1.10.4-bullseye 

RUN apt-get -y update 
RUN apt-get -y install coreutils cmake gcc g++ python python3 python3-pip python3-venv git libblas-dev liblapack-dev
RUN pip install --upgrade pip
RUN pip install poetry

WORKDIR /symmetry-benchmarks

COPY ./Makefile ./Makefile

COPY ./deps/taco ./deps/taco
COPY ./deps/splatt ./deps/splatt
COPY ./deps/SparseRooflineBenchmark ./deps/SparseRooflineBenchmark
COPY ./deps/SySTeC ./deps/SySTeC
RUN make deps

COPY ./Project.toml ./Project.toml
COPY ./setup.jl ./setup.jl
COPY ./pyproject.toml ./pyproject.toml
RUN make envs

COPY ./run_SySTeC.jl ./run_SySTeC.jl
RUN julia run_SySTeC.jl

COPY ./kernels ./kernels
RUN make all

COPY ./run_benchmarks.sh run_benchmarks.sh

COPY ./charts ./charts
COPY ./plot_results.py ./plot_results.py
COPY ./README.md ./README.md
