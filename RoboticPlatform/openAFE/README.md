openAFE
===========================

openAFE is a C++ library to extract a subset of common auditory representations from a binaural recording or from a stream of binaural audio data, based on the [Two!Ears Auditory Front-End](https://github.com/TWOEARS/auditory-front-end)

## Installation

The openAFE can be installed easily by automake. To do so, type the following commands in a terminal :

```Shell
>> cd openAFE
>> mkdir build
>> cd build
>> ../configure
>> make
>> sudo make install
```

This repository contains some DEMOs. They uses .mat files as input, so they need Matlab to be installed on your computer. To install the library and to compile the DEMOs, adapt the following commands according to your own Matlab directory before using :

```Shell
>> cd openAFE
>> mkdir build
>> cd build
>> ../configure LDFLAGS="-L/usr/local/MATLAB/R2015a/bin/glnxa64" CPPFLAGS="-I/usr/local/MATLAB/R2015a/extern/include -Wl,-rpath=/usr/local/MATLAB/R2015a/bin/glnxa64"
>> make
>> sudo make install
```

## How to run DEMOs
Check the [examples](examples/) directory to see how to use the DEMOs.
