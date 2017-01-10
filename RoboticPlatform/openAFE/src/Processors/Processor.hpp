#ifndef PROCESSOR_HPP
#define PROCESSOR_HPP

#include <memory>
#include <string>
#include <stdint.h>

namespace openAFE {

	/* The type of the processing */
	enum procType {
		_unknow,
		_inputProc,
		_preProc,
		_gammatone,
		_ihc,
		_ild,
		_ratemap,
		_crosscorrelation,
		_itd
	};
	
	/* The father class for all processors in rosAFE */
	class Processor {
		
		protected:
			
			procType type;						// The type of this processing
			std::string name;
			bool hasTwoOutputs; 				// Flag indicating the need for two outputs
			uint64_t nfr;
			
			uint32_t fsIn;						// Sampling frequency of input (i.e., prior to processing)
			uint32_t fsOut;			 			// Sampling frequency of output (i.e., resulting from processing)
			
			double bufferSize_s;

			std::size_t nChannel;			
			
		public:
					
			/* PROCESSOR Super-constructor of the processor class
			  * 
			  * INPUT ARGUMENTS:
			  * fsIn : Input sampling frequency (Hz)
			  * fsOut : Output sampling frequency (Hz)
			  * procName : Name of the processor to implement
			  * parObj : Parameters instance to use for this processor
			  */
			Processor (const double bufferSize_s, const uint32_t fsIn, const uint32_t fsOut, const std::size_t nChannel, const std::string& nameArg, procType typeArg);
			
			~Processor ();
			
			/* PROCESSOR abstract methods (to be implemented by each subclasses): */
			/* PROCESSCHUNK : Returns the output from the processing of a new chunk of input */
			virtual void processChunk () = 0;
			/* RESET : Resets internal states of the processor, if any */
			virtual void reset () = 0;
            
            virtual void prepareForProcessing () = 0;

			/* Returns a const reference of the type of this processor */		
			const procType getType();
			
			/* Compare only the information of the two processors */
			const bool compareBase ( Processor& toCompare );

			const uint32_t getFsOut();

			const uint32_t getFsIn();
			
			const uint64_t getNFR();
			
			void setNFR ( const uint64_t nfrArg );
			
			const std::string getName();		
			
			const double getBufferSize_s();

			virtual std::string get_upperProcName()	= 0;
			
			std::size_t get_nChannel();					
	};

};


#endif /* PROCESSOR_HPP */
