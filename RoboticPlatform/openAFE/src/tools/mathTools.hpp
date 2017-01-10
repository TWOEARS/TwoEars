#ifndef MATHTOOLS_HPP
#define MATHTOOLS_HPP

#define ERB_L 24.7
#define ERB_Q 9.265
#define EPSILON 2.2204e-16

#include <stdint.h>
#include <vector>
#include <complex>
#include <math.h> /* M_PI, exp, log, log10 */
#include <fftw3.h>

namespace openAFE {
		
		/// freq2erb - converts to frequencyscale erbscale.
		/// Uses a scaling based on the equivalent rectangular bandwidth
		/// (ERB) of an auditory filter at centre frequency fc:
		/// ERB(fc) = 24.7 + fc[Hz]/9.265 (Glasberg and Moore, JASA 1990). 
		/// 
		///   freq = input vector in Hz
		///   erb  = erbscaled output vector
		/// 
		///
			 
		template<typename T = double>
		inline		
		T freq2erb( T freq )  {
			return ERB_Q * log ( 1 + freq / ( ERB_L * ERB_Q ));
		}		 
		 
		template<typename T = double>
		void freq2erb(T* firstValue_freq, size_t dim, T* firstValue_erb)  {
			for ( unsigned int i = 0 ; i < dim ; ++i )
				*( firstValue_erb + i ) = freq2erb ( *( firstValue_freq + i ) );
		}
		
		/// erb2freq - converts erbscale to frequencyscale
		template<typename T = double>
		inline		
		T erb2freq( T erb )  {
			return ERB_L * ERB_Q * ( exp( erb / ERB_Q ) - 1 );
		}
				 
		template<typename T = double>
		void erb2freq( T* firstValue_erb, size_t dim, T* firstValue_freq ) {
			for ( size_t i = 0 ; i < dim ; ++i )
				*( firstValue_freq + i ) = erb2freq ( *( firstValue_erb + i ) );
		}
			
		/// conv - Convolution and polynomial multiplication.
		/// C = conv(A, B) convolves vectors A and B.  The resulting vector is
		/// length MAX([LENGTH(A)+LENGTH(B)-1,LENGTH(A),LENGTH(B)]).
		/// 
		/// Based On : http://toto-share.com/2011/11/cc-convolution-source-code/
		/// 
		template<typename T = double>
		std::vector<T> conv( T* A, int32_t lenA, T* B, int32_t lenB ) {
			int32_t nconv;
			int32_t j, i1;
			T tmp;
				 
			//allocated convolution array	
			nconv = lenA+lenB-1;
			std::vector<T > C ( nconv, 0 );

			//convolution process
			for ( int32_t i = 0 ; i < nconv; i++ ) {
				i1 = i;
				tmp = 0.0;
				for (j=0; j<lenB; j++)
				{
					if(i1>=0 && i1<lenA)
						tmp = tmp + (A[i1]*B[j]);
		 
					i1 = i1-1;
					C[i] = tmp;
				}
			}
		 
			//return convolution array
			return( C );
		}	
	
		/// linspace - Linearly spaced vector.
		/// linspace(X1, X2, N) generates a std::vector of N linearly
		/// equally spaced points between X1 and X2.
		/// 
		/// Source : https://gist.github.com/jmbr/2375233
		template <typename T = double>
		std::vector<T> linspace(T a, T b, size_t N) {
		  T h = (b - a) / static_cast<T>(N-1);
		  std::vector<T> xs(N);
		  typename std::vector<T>::iterator x;
		  T val;
		  for (x = xs.begin(), val = a; x != xs.end(); ++x, val += h)
			*x = val;
		  return xs;
		}

		template <typename T = double>
		void multiplication( T* firstValue_vect1, T* firstValue_vect2, size_t dim, T* firstValue_dest ) {
			for ( size_t i = 0 ; i < dim ; ++i )
				*( firstValue_dest + i ) = *( firstValue_vect1 + i ) * *( firstValue_vect2 + i );
		}

		template <typename T = double>
		T sum( T* firstValue_src, size_t dim ) {
			T sum = 0;
			for ( size_t i = 0 ; i < dim ; ++i )
				sum += *( firstValue_src + i );
			return sum;
		}

		template <typename T = double>
		T sumPow( T* firstValue_src, size_t dim, double power ) {
			T sum = 0;
			for ( size_t i = 0 ; i < dim ; ++i )
				sum += pow( *( firstValue_src + i ), power);
			return sum;
		}
		
		template <typename T = double>
		T mean( T* firstValue_src, size_t dim ) {
			return sum( firstValue_src, dim ) / dim;
		}
		
		template <typename T = double>
		T meanSquare( T* firstValue_src, size_t dim ) {
			return sumPow( firstValue_src, dim, 2 ) / dim;
		}
		
	    /// NEXTPOW2(N) returns the first P such that 2.^P >= abs(N).  It is
		/// often useful for finding the nearest power of two sequence
		/// length for FFT operations.
		template <typename T = double>
		T nextpow2( T N ) {
		  return ceil(log2(abs( N ) ) );
		}

		/// CONJ   Complex conjugate.
		///   CONJ(X) is the complex conjugate of X.
		///   For a complex X, CONJ(X) = REAL(X) - i*IMAG(X).

		template <typename T = double>
		inline
		void _conj( std::complex<T>& val ) {
			val.imag( -1 * val.imag() );
		}
		
		template <typename T = double>
		std::vector<std::complex<T> > conj( std::complex<T> *val, std::size_t dim ) {
			std::vector<std::complex<T> > tmp(dim);
			for ( std::size_t ii = 0 ; ii < dim ; ++ii )
				tmp[ii] = conj( *( val + ii ) );
		  return tmp;
		}

		template <typename T = double>
		void _conj( std::vector<std::complex<T> >& val ) {
			for ( std::size_t ii = 0 ; ii < val.size() ; ++ii )
				_conj( val[ii] ) ;
		}
				
		/// fft(X, lengthSignal, N) is the discrete Fourier transform (DFT) of vector X.
		template <typename T = double>		
		std::vector<std::complex<T> > fft( T *val, std::size_t valN, std::size_t fft_N ) {

			std::vector<double> fftIn(fft_N,0);
			
			// Zero padding
			if ( fft_N > valN ) {
				for( std::size_t ii = 0 ; ii < valN ; ++ii )
					fftIn[ii] = *(val+ii);
			// Truncating		
			} else for( std::size_t ii = 0 ; ii < fft_N ; ++ii )
					fftIn[ii] = *(val+ii);
		
			std::vector<std::complex<T> > outVect ( floor(fft_N/2) + 1 );
			fftw_complex *out = reinterpret_cast<fftw_complex*>(outVect.data());
			
			fftw_plan p = fftw_plan_dft_r2c_1d(fft_N, fftIn.data(), out, FFTW_ESTIMATE);
			
			fftw_execute(p);

			fftw_destroy_plan( p );
			return outVect;
		}
		
		/// ifft(X) is the inverse discrete Fourier transform of X.
		template <typename T = double>		
		std::vector<T> ifft( std::complex<T> *val, std::size_t valN, std::size_t fft_N ) {
		
			std::vector<T> resultVec ( fft_N );
			fftw_complex *out = reinterpret_cast<fftw_complex*>( val );
			
			fftw_plan ip = fftw_plan_dft_c2r_1d(fft_N, out, resultVec.data(), FFTW_ESTIMATE);
			
			fftw_execute(ip);
			
			// resultVec.resize( valN );
			for ( std::size_t ii = 0 ; ii < fft_N ; ++ii )
				resultVec[ii] /= fft_N;

			fftw_destroy_plan( ip );
			return resultVec;
		}

		///  max    Largest component.
		template <typename T = double>		
		T max( T *firstValue, std::size_t dim, std::size_t *index = NULL ) {
			T max = *firstValue;
			for ( std::size_t ii = 0 ; ii < dim ; ++ii )
				if ( *( firstValue + ii ) < max) {
					max = *( firstValue + ii );
					*index = ii;
				}
			return max;
		}
						
}; /* namespace openAFE */


#endif /* MATHTOOLS_HPP */
