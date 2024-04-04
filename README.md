# symmetry-benchmarks

## Library Configuration

### SPLATT
From within the splatt directory, run the following commands:
`./configure --prefix=/PATH/TO/REPO/symmetry-benchmarks/splatt`

`make`

`make install`


## Running Benchmarks

### MTTKRP
From within the kernels/mttkrp directory:
`./compile_splatt.sh`

`./splatt.out c s ../../data/amino.tns 1`