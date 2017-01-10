bin_PROGRAMS = DEMO_input DEMO_preProc DEMO_filterbank DEMO_ihc DEMO_ild DEMO_ratemap DEMO_crossCorrelation

MATFILESLIB_LIBS = -lmat -lmx

AM_CXXFLAGS=$(CPPFLAGS) $(CXXFLAGS)

noinst_LIBRARIES = libmatFiles.a
libmatFiles_a_SOURCES = matFiles.hpp
libmatFiles_a_SOURCES += matFiles.cpp 

DEMO_input_SOURCES = DEMO_input.cpp
DEMO_input_LDADD = ../src/libopenAFE.la libmatFiles.a $(MATFILESLIB_LIBS)

DEMO_preProc_SOURCES = DEMO_preProc.cpp
DEMO_preProc_LDADD = ../src/libopenAFE.la libmatFiles.a $(MATFILESLIB_LIBS)

DEMO_filterbank_SOURCES = DEMO_filterbank.cpp
DEMO_filterbank_LDADD = ../src/libopenAFE.la libmatFiles.a $(MATFILESLIB_LIBS)

DEMO_ihc_SOURCES = DEMO_ihc.cpp
DEMO_ihc_LDADD = ../src/libopenAFE.la libmatFiles.a $(MATFILESLIB_LIBS)

DEMO_ild_SOURCES = DEMO_ild.cpp
DEMO_ild_LDADD = ../src/libopenAFE.la libmatFiles.a $(MATFILESLIB_LIBS)

DEMO_ratemap_SOURCES = DEMO_ratemap.cpp
DEMO_ratemap_LDADD = ../src/libopenAFE.la libmatFiles.a $(MATFILESLIB_LIBS)

DEMO_crossCorrelation_SOURCES = DEMO_crossCorrelation.cpp
DEMO_crossCorrelation_LDADD = ../src/libopenAFE.la libmatFiles.a $(MATFILESLIB_LIBS)
