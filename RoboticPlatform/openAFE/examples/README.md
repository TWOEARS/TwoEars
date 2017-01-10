openAFE Examples
===========================

## Input
Once the installation is finished, you can run the demo examples. You should provide a .mat file containing an array called earSignals (matrix of m x 2) corresponding to the binaural input signal and a value called fsHz which is the sampling frequency.

## Output
The output is a .mat file as well. This file contains the output datas in two separate matrices (left - right), and a value called fsHz which is the sampling frequency.

## Usage
For each demo, you should provide at least following informations : 

* inFilePath : the path of the input .mat file
* outputName : the name of the output .mat file (including the .mat extention)

The other arguments are optional. If missing, the default values will be used. In this demo examples, in any case, the dependent processors of the requested processor will be initialized with theirs default parameters.

## Input Processor

```Shell
>> ./DEMO_input inFilePath outputName bufferSize_s doNormalize normalizeValue
```

* 'bufferSize_s' : The buffer size in seconds
* 'doNormalize' : Flag to activate input normalization  ( 0 or 1 )
* 'normalizeValue' : Normalization value

## Pre-Processor
```Shell
>> ./DEMO_preProc inFilePath outputName bRemoveDC cutoffHzDC bPreEmphasis coefPreEmphasis bNormalizeRMS intTimeSecRMS bLevelScaling refSPLdB bMiddleEarFiltering middleEarModel bUnityComp
```

* 'bRemoveDC_s' : Flag to activate DC removal filter ( 0 or 1 )
* 'cutoffHzDC' : Cutoff frequency in Hz of the high-pass filter
* 'bPreEmphasis' : Flag to activate pre-emphasis filter  ( 0 or 1 )
* 'coefPreEmphasis' : Coefficient of first-order high-pass filter
* 'bNormalizeRMS' : Flag to activate RMS normalization  ( 0 or 1 )
* 'intTimeSecRMS' : Time constant used for RMS estimation
* 'bLevelScaling' : Flag to apply level sacling to given reference  ( 0 or 1 )
* 'refSPLdB' : Reference dB SPL to correspond to input RMS of 1
* 'bMiddleEarFiltering' : Flag to apply middle ear filtering  ( 0 or 1 )
* 'middleEarModel' : Middle ear filter model (jepsen or lopezpoveda)
* 'bUnityComp' : Compensation to have maximum of unity gain for middle ear filter ( 0 or 1 )
   

## Gammatone Filterbank
```Shell
>> ./DEMO_filterbank inFilePath outputName fb_lowFreqHz fb_highFreqHz fb_nERBs fb_nChannels fb_nGamma fb_bwERBs
```

* 'fb_lowFreqHz' : Lowest center frequency
* 'fb_highFreqHz' : Highest center frequency
* 'fb_nERBs' : Distance between neighboring filters in ERBs
* 'fb_nChannels' : Channels center frequencies (Hz)
* 'fb_nGamma' : Gammatone rising slope order
* 'fb_bwERBs' : Bandwidth of the filters in ERBs

## Inner Hair Cell
```Shell
>> ./DEMO_ihc inFilePath outputName method
```

* 'method' : The IHC method name (none, halfwave, fullwave, square, dau)

## Interaural Level Difference processor
```Shell
>> ./DEMO_ild inFilePath outputName wSizeSec hSizeSec windowType
```

* 'wSizeSec' : Window duration in seconds
* 'hSizeSec' : Step size between windows in seconds
* 'wname' : Window shape descriptor (hamming, hanning, hann, blackman, triang, sqrt)

## Ratemap
```Shell
>> ./DEMO_ratemap inFilePath outputName wSizeSec hSizeSec scailingArg decaySec wname
```

* 'wSizeSec' : Window duration in seconds
* 'hSizeSec' : Step size between windows in seconds
* 'scailingArg' : (power or magnitude)
* 'decaySec' : Signal-smoothing leaky integrator time constant 
* 'wname' : (hamming, hanning, hann, blackman, triang, sqrt)

## Cross correlation
```Shell
>> ./DEMO_crossCorrelation inFilePath outputName wSizeSec hSizeSec maxDelaySec wname
```

* 'wSizeSec' : Window duration in seconds
* 'hSizeSec' : Step size between windows in seconds
* 'maxDelaySec' : Maximum delay in cross-correlation computation in seconds
* 'wname' : Window shape descriptor (hamming, hanning, hann, blackman, triang, sqrt)
