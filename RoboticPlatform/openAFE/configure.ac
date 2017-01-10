AC_INIT([openAFE], [1.0], [musabini@isir.upmc.fr])
AM_INIT_AUTOMAKE([subdir-objects])
AC_LANG(C++)
AC_CONFIG_MACRO_DIR([m4])

have_pthreads=no
have_matlab=no

dont_install=no

AC_SEARCH_LIBS([pthread_create], [pthread], [have_pthreads=yes], [dont_install=yes])

AC_SEARCH_LIBS([matOpen], [mat], [have_matlab=yes])
AC_SEARCH_LIBS([mxCreateDoubleScalar], [mx], [], [have_matlab=no])

AC_CHECK_HEADERS([string.h memory.h stdlib.h fftw3.h boost/circular_buffer.hpp], [], [dont_install=yes])

if test "x${have_pthreads}" = "xyes"; then
  AC_CHECK_HEADERS([pthread.h], [], [have_pthreads=no])
fi

if test "x${have_matlab}" = "xyes"; then
  AC_CHECK_HEADERS([mat.h], [], [have_matlab=no])
fi

LT_INIT
AC_PROG_CPP
CXXFLAGS='-Wall -O3 -Wsign-compare -std=c++11 -pthread -D_REENTRANT -DHAVE_INLINE -funroll-loops -ftree-vectorize -ftree-vectorizer-verbose=0'
AC_SUBST([CC])

if test "x${dont_install}" = "xno"; then
  AC_CONFIG_FILES(Makefile)
  AC_CONFIG_FILES(src/Makefile)
  AC_CONFIG_FILES(src/tools/Makefile)
  AC_CONFIG_FILES(src/Signals/Makefile)
  AC_CONFIG_FILES(src/Filters/Makefile)
  AC_CONFIG_FILES(src/Processors/Makefile)
  if test "x${have_matlab}" = "xyes"; then
    AC_CONFIG_FILES(examples/Makefile)
  fi
else
  AC_MSG_NOTICE([----------------------------------------------------------------------------------------------------])
  AC_MSG_NOTICE([----------------------------------------------------------------------------------------------------])
  AC_MSG_NOTICE([--------------------------------Please install the mising libraries.--------------------------------])
  AC_MSG_NOTICE([----------------------------------------------------------------------------------------------------])
  AC_MSG_NOTICE([----------------------------------------------------------------------------------------------------])
fi

AC_OUTPUT
