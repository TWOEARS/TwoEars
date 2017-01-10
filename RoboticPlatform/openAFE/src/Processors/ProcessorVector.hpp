#ifndef PROCESSORVECTOR_HPP
#define PROCESSORVECTOR_HPP

#include <vector>
#include <memory>

#include "Processor.hpp"
/* This class assambles the same type processors of the openAFE library. */

namespace openAFE {
	
	/* Each processor has its own template. */
	template<typename proccessorT>
	class ProcessorVector {
		
	private:
	
		typedef std::shared_ptr<proccessorT > 						processorSharedPtr;
		typedef std::vector<processorSharedPtr > 					processorSharedPtrVector;
		typedef typename processorSharedPtrVector::iterator 		processorSharedPtrVectorIterator;
		typedef typename processorSharedPtrVector::const_iterator 	processorSharedPtrVectorConstIterator;
				
	public:

		/* Each type of processor has its own vector */		
		processorSharedPtrVector processorVector;
				
		ProcessorVector() {}
		~ProcessorVector() {
			this->clear ( );
		}

		/* existsInputProcessor : return true if the asked processor exists alreadys
		 * with the same parameters and with the same informations.
		 * */
		const bool existsProcessor( const processorSharedPtr procObjArg ) {
			for ( processorSharedPtrVectorConstIterator it = processorVector.begin() ; it != processorVector.end() ; ++it )
				if ( *(*it) == (*procObjArg) )
					return true;
			return false;
		}

		const bool existsProcessorName( const char *name ) {
			for ( processorSharedPtrVectorConstIterator it = processorVector.begin() ; it != processorVector.end() ; ++it )
				if ( (*it)->getName() == name )
					return true;
			return false;
		}

		/* addInputProc : adds the argument processor to the structure if and only if
		 * the argument doesnt exist already in the inputProcVector and is a inputProc.
		 * 
		 * Returns true if the processor is added to the structure.
		 * Returns false if the structure exists alreay, or if it is not a inputProc.
		 * */
		const bool addProcessor( const processorSharedPtr procObjArg ) {

			/* Verify if this processors doesnt exists already */
			bool existsAlready = this->existsProcessor( procObjArg );
			
			if ( ! existsAlready )	{
				/* Verify the procesor type */
				// assert ( *(procObjArg->getType()) == 0 ); // FIXME : how can I do this ?
				/* Add the argument processor to the structure */
				this->processorVector.push_back( std::move( procObjArg ) ); // FIXME : is std::move is realy useful ?
			}
			
			return (!existsAlready);
		}
		
		/* getInputProcessor : returns a shared pointer to the asked input processor.
		 * If the processor doesn't exists, returns a null pointer.
		 * */		
		const processorSharedPtr getProcessor ( const int32_t rangArg ) {
			if ( rangArg <= this->getSize ( ) )
				return this->processorVector[rangArg];
			else
				return nullptr;
		}

		/* getInputProcessor : returns a shared pointer to the asked input processor.
		 * If the processor doesn't exists, returns a null pointer.
		 * */		
		const processorSharedPtr getProcessor ( const std::string& nameArg ) {
			for ( processorSharedPtrVectorIterator it = processorVector.begin() ; it != processorVector.end() ; ++it )
				if ( (*it)->getName() == nameArg )
					return *it;
			return nullptr;
		}
				
		/* removeInputProcessor : returns true if the asked processor is removed.
		 * returns false if the processor doesnt exist */
		const bool removeProcessor ( const std::string& nameArg ) {
			for ( processorSharedPtrVectorIterator it = processorVector.begin() ; it != processorVector.end() ; ++it )
				if ( (*it)->getName() == nameArg ) {
					this->processorVector.erase( it );
					return true;
				}
			return false;
		}

		const uint32_t getSize ( ) {
			return this->processorVector.size( );
		}
				
		/* Deletes all the processors, but not this object */
		void clear ( ) {
			this->processorVector.clear();
		}
	};
};

#endif /* PROCESSORVECTOR_HPP */
