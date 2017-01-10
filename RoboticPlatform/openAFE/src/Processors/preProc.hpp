#ifndef PREPROC_HPP
#define PREPROC_HPP

#include <stdlib.h>		/* abs */
#include <math.h>       /* exp, pow*/
	
#include "TDSProcessor.hpp"
#include "inputProc.hpp"

#include "../Filters/bwFilter.hpp"
#include "../Filters/GenericFilter.hpp"

#include "../tools/mathTools.hpp"

/* 
 * preProc :
 * 
 * 
 * */


namespace openAFE {

	enum middleEarModel{
		_jepsen,
		_lopezpoveda
	};
	
	class PreProc : public TDSProcessor<double> {

		private:
			
			typedef std::shared_ptr< bwFilter > bwFilterPtr;
			typedef std::shared_ptr< GenericFilter<double, double, double, double> > genericFilterPtr;
			
			double meFilterPeakdB;

			/* Pointers to Filter Objects */				
			bwFilterPtr dcFilter_l;
			bwFilterPtr dcFilter_r;
			
			genericFilterPtr preEmphFilter_l;
			genericFilterPtr preEmphFilter_r;
			
			genericFilterPtr agcFilter_l;
			genericFilterPtr agcFilter_r;

			genericFilterPtr midEarFilter_l;
			genericFilterPtr midEarFilter_r;
			
			std::shared_ptr<InputProc > upperProcPtr;
			
			bool pp_bRemoveDC;
			double pp_cutoffHzDC;
			bool pp_bPreEmphasis;
			double pp_coefPreEmphasis;
			bool pp_bNormalizeRMS;
			double pp_intTimeSecRMS;
			bool pp_bLevelScaling;
			double pp_refSPLdB;
			bool pp_bMiddleEarFiltering;
			middleEarModel pp_middleEarModel;
			bool pp_bUnityComp;
	
            void verifyParameters();
						
			// Actual Processing
			void process ( std::size_t dim1, double* firstValue1, std::size_t dim2, double* firstValue2, std::shared_ptr <TimeDomainSignal<double> > PMZ , bwFilterPtr dcFilter,
																																						   genericFilterPtr preEmphFilter,
																																						   genericFilterPtr agcFilter,
																																						   double* tmp );
										
		public:
		
			/* PreProc */
			PreProc (const std::string nameArg, std::shared_ptr<InputProc > upperProcPtr, bool pp_bRemoveDC = false,
																						  double pp_cutoffHzDC = 20,
																						  bool pp_bPreEmphasis = false,
																						  double pp_coefPreEmphasis =  0.97,
																						  bool pp_bNormalizeRMS = false,
																						  double pp_intTimeSecRMS = 0.5,
																						  bool pp_bLevelScaling = false,
																						  double pp_refSPLdB = 100,
																						  bool pp_bMiddleEarFiltering = false,
																						  middleEarModel pp_middleEarModel = _jepsen,
																						  bool pp_bUnityComp = true );
				
			~PreProc ();
			
			void processChunk ();
			
			void prepareForProcessing ();

			/* Comapres informations and the current parameters of two processors */
			bool operator==( PreProc& toCompare );

			// getters
			bool get_pp_bRemoveDC();
			double get_pp_cutoffHzDC();
			bool get_pp_bPreEmphasis();
			double get_pp_coefPreEmphasis();
			bool get_pp_bNormalizeRMS();
			double get_pp_intTimeSecRMS();
			bool get_pp_bLevelScaling();
			double get_pp_refSPLdB();
			bool get_pp_bMiddleEarFiltering();
			middleEarModel get_pp_middleEarModel();
			bool get_pp_bUnityComp();

			// setters			
			void set_pp_bRemoveDC(const bool arg);
			void set_pp_cutoffHzDC(const double arg);
			void set_pp_bPreEmphasis(const bool arg);
			void set_pp_coefPreEmphasis(const double arg);
			void set_pp_bNormalizeRMS(const bool arg);
			void set_pp_intTimeSecRMS(const double arg);
			void set_pp_bLevelScaling(const bool arg);
			void set_pp_refSPLdB(const double arg);
			void set_pp_bMiddleEarFiltering(const bool arg);
			void set_pp_middleEarModel(const middleEarModel arg);
			void set_pp_bUnityComp(const bool arg);	

			std::string get_upperProcName();
				
	}; /* class PreProc */
}; /* namespace openAFE */

#endif /* PREPROC_HPP */
