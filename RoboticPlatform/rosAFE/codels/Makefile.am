#
# Copyright (c) 2014 LAAS/CNRS
# All rights reserved.
#
# Redistribution  and  use  in  source  and binary  forms,  with  or  without
# modification, are permitted provided that the following conditions are met:
#
#   1. Redistributions of  source  code must retain the  above copyright
#      notice and this list of conditions.
#   2. Redistributions in binary form must reproduce the above copyright
#      notice and  this list of  conditions in the  documentation and/or
#      other materials provided with the distribution.
#
# THE SOFTWARE  IS PROVIDED "AS IS"  AND THE AUTHOR  DISCLAIMS ALL WARRANTIES
# WITH  REGARD   TO  THIS  SOFTWARE  INCLUDING  ALL   IMPLIED  WARRANTIES  OF
# MERCHANTABILITY AND  FITNESS.  IN NO EVENT  SHALL THE AUTHOR  BE LIABLE FOR
# ANY  SPECIAL, DIRECT,  INDIRECT, OR  CONSEQUENTIAL DAMAGES  OR  ANY DAMAGES
# WHATSOEVER  RESULTING FROM  LOSS OF  USE, DATA  OR PROFITS,  WHETHER  IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR  OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
lib_LTLIBRARIES = librosAFE_codels.la

librosAFE_codels_la_SOURCES=	rosAFE_c_types.h
librosAFE_codels_la_SOURCES+=	rosAFE_codels.cc
librosAFE_codels_la_SOURCES+=	rosAFE_init_codels.cc
librosAFE_codels_la_SOURCES+=	rosAFE_input_codels.cc
librosAFE_codels_la_SOURCES+=	rosAFE_preProc_codels.cc
librosAFE_codels_la_SOURCES+=	rosAFE_gammatoneProc_codels.cc
librosAFE_codels_la_SOURCES+=	rosAFE_ihcProc_codels.cc
librosAFE_codels_la_SOURCES+=	rosAFE_ildProc_codels.cc
librosAFE_codels_la_SOURCES+=	rosAFE_ratemapProc_codels.cc
librosAFE_codels_la_SOURCES+=	rosAFE_crossCorrelationProc_codels.cc

librosAFE_codels_la_SOURCES+=	stateMachine.hpp
librosAFE_codels_la_SOURCES+=	stateMachine.cpp
librosAFE_codels_la_SOURCES+=	Ports.hpp
librosAFE_codels_la_SOURCES+=	Ports.cpp

librosAFE_codels_la_CPPFLAGS=	$(requires_CFLAGS)
librosAFE_codels_la_CPPFLAGS+=	-Wall -g -O -std=c++11 -DHAVE_INLINE -pthread -D_REENTRANT -Wunused-but-set-variable
librosAFE_codels_la_LDFLAGS=	$(requires_LIBS)
librosAFE_codels_la_LDFLAGS+=	-release $(PACKAGE_VERSION)
librosAFE_codels_la_LDFLAGS+=	-lopenAFE # -lsndfile -lfftw3f
# idl  mappings
BUILT_SOURCES=	rosAFE_c_types.h
CLEANFILES=	${BUILT_SOURCES}
rosAFE_c_types.h: ${top_srcdir}/rosAFE.gen
	${GENOM3}  mappings \
	  -MD -MF .deps/$@.d -MT $@ --signature -l c $< >$@

-include .deps/rosAFE_c_types.h.d
