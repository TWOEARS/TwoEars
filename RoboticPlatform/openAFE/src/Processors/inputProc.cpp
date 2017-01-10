#include "inputProc.hpp"

using namespace openAFE;
using namespace std;

			void InputProc::process ( double* firstValue, size_t dim, shared_ptr <TimeDomainSignal<double> > PMZ ) {
				if ( this->in_doNormalize ) {
					double value;	
					for ( uint32_t i = 0 ; i < dim ; ++i ) {
						value = ( *( firstValue + i ) ) / this->in_normalizeValue;
						PMZ->appendFrame( &value );
					}
				} else {
					for ( uint32_t i = 0 ; i < dim ; ++i )
						PMZ->appendFrame( firstValue + i );
				}
				
				PMZ->setLastChunkSize( dim );
			}

			InputProc::InputProc ( const string nameArg, const uint32_t fs, const double bufferSize_s, bool in_doNormalize, uint64_t in_normalizeValue ) : TDSProcessor<double> (nameArg, fs, fs, bufferSize_s, _inputProc) {
				if ( in_normalizeValue != 0 ) {
					this->in_doNormalize = in_doNormalize;
					this->in_normalizeValue = in_normalizeValue;
				}
			}
				
			InputProc::~InputProc () {	}
			
			/* This function does the asked calculations. 
			 * The inputs are called "privte memory zone". The asked calculations are
			 * done here and the results are stocked in that private memory zone.
			 * However, the results are not publiched yet on the output vectors.
			 */
			void InputProc::processChunk (double* inChunkLeft, size_t leftDim, double* inChunkRight, size_t rightDim ) {

				assert ( leftDim == rightDim );
						
				thread leftThread( &InputProc::process, this, inChunkLeft, leftDim, this->leftPMZ );
				thread rightThread( &InputProc::process, this, inChunkRight, rightDim, this->rightPMZ );
						
				leftThread.join();                // pauses until left finishes
				rightThread.join();               // pauses until right finishes	
			}
			
			void InputProc::processChunk () { }
						
			void InputProc::prepareForProcessing () { }

			/* Comapres informations and the current parameters of two processors */
			bool InputProc::operator==( InputProc& toCompare ) {
				if ( this->compareBase( toCompare ) ) {
					if  ( ( this->get_in_doNormalize() == toCompare.get_in_doNormalize() ) and
					    ( this->get_in_normalizeValue() == toCompare.get_in_normalizeValue() ) )			
					return true;
				} return false;
			}
			
			bool InputProc::get_in_doNormalize() {return this->in_doNormalize;}
			uint64_t InputProc::get_in_normalizeValue() {return this->in_normalizeValue;}

			// setters			
			void InputProc::set_in_doNormalize(const bool arg) {this->in_doNormalize=arg;}
			void InputProc::set_in_normalizeValue(const uint64_t arg) { if ( arg > 0 ) this->in_normalizeValue=arg;}			
	
			string InputProc::get_upperProcName()	{return "BASS";}
