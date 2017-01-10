#ifndef INPUTPROC_HPP
#define INPUTPROC_HPP

#define MAXCODABLEVALUE 2147483647

#include <thread>
#include <stdint.h>

#include "TDSProcessor.hpp"
#include "../tools/mathTools.hpp"

/* 
 * inputProc is the first processor of the processor tree. It receves the audio
 * from any classical C type arrays and stores the data in  two time domain signals (left and right).
 * 
 * When needed, the inputProc normalizes that input data as well.
 * 
 * in_doNormalize : flag to activatedesactivate the normalization
 * in_normalizeValue : th normalization value
 * 
 * */
 
namespace openAFE {

	class InputProc : public TDSProcessor<double> {
					
		private:
			
			bool in_doNormalize;
			uint64_t in_normalizeValue;
									
			void process ( double* firstValue, std::size_t dim, std::shared_ptr <TimeDomainSignal<double> > PMZ );

		public:

			InputProc ( const std::string nameArg, const uint32_t fs, const double bufferSize_s, bool in_doNormalize = true, uint64_t in_normalizeValue = MAXCODABLEVALUE );
				
			~InputProc ();
			
			/* This function does the asked calculations. 
			 * The inputs are called "privte memory zone". The asked calculations are
			 * done here and the results are stocked in that private memory zone.
			 * However, the results are not publiched yet on the output vectors.
			 */
			void processChunk (double* inChunkLeft, std::size_t leftDim, double* inChunkRight, std::size_t rightDim );
			
			void processChunk ();
						
			void prepareForProcessing ();

			/* Comapres informations and the current parameters of two processors */
			bool operator==( InputProc& toCompare );
			
			bool get_in_doNormalize();
			uint64_t get_in_normalizeValue();

			// setters			
			void set_in_doNormalize(const bool arg);
			void set_in_normalizeValue(const uint64_t arg);		
	
			std::string get_upperProcName();
			
	}; /* class InputProc */
}; /* namespace openAFE */

#endif /* INPUTPROC_HPP */
