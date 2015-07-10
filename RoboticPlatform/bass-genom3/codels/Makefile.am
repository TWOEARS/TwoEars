# Copyright (c) 2014, LAAS/CNRS
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
lib_LTLIBRARIES = libbass_codels.la

libbass_codels_la_SOURCES=	bass_c_types.h
libbass_codels_la_SOURCES+=	bass_codels.c
libbass_codels_la_SOURCES+=	bass_capture_codels.c
libbass_codels_la_SOURCES+=	bass_socket_codels.c
libbass_codels_la_SOURCES+=     Ports.h
libbass_codels_la_SOURCES+=     Ports.c
libbass_codels_la_SOURCES+=     AudioCapture.h
libbass_codels_la_SOURCES+=     AudioCapture.c
libbass_codels_la_SOURCES+=     Sockets.h
libbass_codels_la_SOURCES+=     Sockets.c


libbass_codels_la_CPPFLAGS=	$(requires_CFLAGS)
libbass_codels_la_LDFLAGS=	$(requires_LIBS)
libbass_codels_la_LDFLAGS+=	-release $(PACKAGE_VERSION)


# idl  mappings
BUILT_SOURCES=	bass_c_types.h
CLEANFILES=	${BUILT_SOURCES}
bass_c_types.h: ${top_srcdir}/bass.gen
	${genom3}  mappings \
	  -MD -MF .deps/$@.d -MT $@ --signature -l c $< >$@

-include .deps/bass_c_types.h.d
