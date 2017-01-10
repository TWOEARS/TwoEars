SUBDIRS = tools Signals Filters Processors
AUTOMAKE_OPTIONS = subdir-objects

AM_CXXFLAGS=$(CXXFLAGS)
AM_CXXFLAGS+= -lfftw3 -lm

@LTLIBOBJS@
lib_LTLIBRARIES = libopenAFE.la

libopenAFE_la_SOURCES = tools/window.cpp
libopenAFE_la_SOURCES += Signals/Signal.cpp
libopenAFE_la_SOURCES += Filters/bwIIR.cpp
libopenAFE_la_SOURCES += Filters/bwCoef.cpp
libopenAFE_la_SOURCES += Filters/bwFilter.cpp
libopenAFE_la_SOURCES += Filters/GammatoneFilter.cpp
libopenAFE_la_SOURCES += Filters/leakyIntegratorFilter.cpp
libopenAFE_la_SOURCES += Processors/Processor.cpp
libopenAFE_la_SOURCES += Processors/inputProc.cpp
libopenAFE_la_SOURCES += Processors/preProc.cpp
libopenAFE_la_SOURCES += Processors/gammatoneProc.cpp
libopenAFE_la_SOURCES += Processors/ihcProc.cpp
libopenAFE_la_SOURCES += Processors/windowBasedProcs.cpp
libopenAFE_la_SOURCES += Processors/ildProc.cpp
libopenAFE_la_SOURCES += Processors/ratemap.cpp
libopenAFE_la_SOURCES += Processors/windowBasedLAGProcs.cpp
libopenAFE_la_SOURCES += Processors/crossCorrelation.cpp

libopenAFE_la_LIBADD = tools/libtools.a
libopenAFE_la_LIBADD += Signals/libsignals.a
libopenAFE_la_LIBADD += Filters/libfilters.a
libopenAFE_la_LIBADD += Processors/libprocessors.a

toolsdir=$(pkgincludedir)/tools
tools_HEADERS = tools/mathTools.hpp
tools_HEADERS += tools/window.hpp

signaldir=$(pkgincludedir)/Signals
signal_HEADERS = Signals/dataType.hpp
signal_HEADERS += Signals/circularContainer.hpp
signal_HEADERS += Signals/Signal.hpp
signal_HEADERS += Signals/TimeDomainSignal.hpp
signal_HEADERS += Signals/TimeFrequencySignal.hpp
signal_HEADERS += Signals/CorrelationSignal.hpp

filterdir=$(pkgincludedir)/Filters
filter_HEADERS = Filters/GenericFilter.hpp
filter_HEADERS += Filters/CascadeFilters.hpp
filter_HEADERS += Filters/bwIIR.hpp
filter_HEADERS += Filters/bwCoef.hpp
filter_HEADERS += Filters/bwFilter.hpp
filter_HEADERS += Filters/GammatoneFilter.hpp
filter_HEADERS += Filters/leakyIntegratorFilter.hpp

processordir=$(pkgincludedir)/Processors
processor_HEADERS = Processors/Processor.hpp
processor_HEADERS += Processors/TDSProcessor.hpp
processor_HEADERS += Processors/TFSProcessor.hpp
processor_HEADERS += Processors/ProcessorVector.hpp
processor_HEADERS += Processors/inputProc.hpp
processor_HEADERS += Processors/preProc.hpp
processor_HEADERS += Processors/gammatoneProc.hpp
processor_HEADERS += Processors/ihcProc.hpp
processor_HEADERS += Processors/windowBasedProcs.hpp
processor_HEADERS += Processors/ildProc.hpp
processor_HEADERS += Processors/ratemap.hpp
processor_HEADERS += Processors/LAGProcessor.hpp
processor_HEADERS += Processors/windowBasedLAGProcs.hpp
processor_HEADERS += Processors/crossCorrelation.hpp
