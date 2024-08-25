FROM docker.io/library/julia:1.10.4-bullseye 

RUN apt-get -y update 
RUN apt-get -y install coreutils
RUN apt-get -y install cmake
RUN apt-get -y install gcc
RUN apt-get -y install g++
RUN apt-get -y install python
RUN apt-get -y install python3
RUN apt-get -y install git
RUN apt-get -y install libblas-dev
RUN apt-get -y install liblapack-dev

WORKDIR /symmetry-benchmarks

COPY ./Makefile ./Makefile

COPY ./deps ./deps
RUN make deps

COPY ./kernels ./kernels
RUN make all

# COPY spmv_taco.cpp ./spmv_taco.cpp
# COPY spmspv_taco.cpp ./spmspv_taco.cpp
# COPY alpha_taco_rle.cpp ./alpha_taco_rle.cpp
# COPY alpha_opencv.cpp ./alpha_opencv.cpp
# COPY triangle_taco.cpp ./triangle_taco.cpp
# COPY all_pairs_opencv.cpp ./all_pairs_opencv.cpp
# COPY conv_opencv.cpp ./conv_opencv.cpp

# COPY benchmark.hpp ./benchmark.hpp
# COPY npy.hpp ./npy.hpp


# RUN mkdir -p /scratch
# 
# COPY ./Project.toml ./
# COPY ./Manifest.toml ./
# COPY ./Finch.jl ./Finch.jl
# COPY ./TensorDepot.jl ./TensorDepot.jl
# 
# COPY ./build_project.sh .
# RUN julia --project=. -e "using Pkg; Pkg.instantiate()"
# COPY ./TensorMarket.jl ./TensorMarket.jl
# 
# COPY ./alpha.sh ./alpha.sh
# COPY ./alpha.jl ./alpha.jl
# RUN bash -e alpha.sh
# 
# COPY ./all_pairs.sh ./all_pairs.sh
# COPY ./all_pairs.jl ./all_pairs.jl
# RUN bash -e all_pairs.sh
# 
# COPY ./spmspv.sh ./spmspv.sh
# COPY ./spmspv.jl ./spmspv.jl
# RUN bash -e spmspv.sh
# 
# COPY ./triangle.sh ./triangle.sh
# COPY ./triangle.jl ./triangle.jl
# RUN bash -e triangle.sh
# 
# COPY ./conv.sh ./conv.sh
# COPY ./conv.jl ./conv.jl
# RUN bash -e conv.sh
# 
# COPY ./spmspv_plot.sh ./spmspv_plot.sh
# COPY ./spmspv_plot.jl ./spmspv_plot.jl
# RUN bash -e spmspv_plot.sh
# 
# COPY ./triangle_plot.sh ./triangle_plot.sh
# COPY ./triangle_plot.jl ./triangle_plot.jl
# RUN bash -e triangle_plot.sh
# 
# COPY ./conv_plot.sh ./conv_plot.sh
# COPY ./conv_plot.jl ./conv_plot.jl
# RUN bash -e conv_plot.sh
# 
# COPY ./alpha_plot.sh ./alpha_plot.sh
# COPY ./alpha_plot.jl ./alpha_plot.jl
# RUN bash -e alpha_plot.sh
# 
# COPY ./all_pairs_plot.sh ./all_pairs_plot.sh
# COPY ./all_pairs_plot.jl ./all_pairs_plot.jl
# RUN bash -e all_pairs_plot.sh
# 