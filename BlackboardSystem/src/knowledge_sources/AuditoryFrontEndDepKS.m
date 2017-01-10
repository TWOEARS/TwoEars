classdef AuditoryFrontEndDepKS < AbstractKS
    % TODO: add description

    %% -----------------------------------------------------------------------------------
    properties (SetAccess = {?DataProcs.BlackboardKsWrapper})
        requests;       
        reqHashs;
        lastBlockEnd;
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = AuditoryFrontEndDepKS( requests )
            obj = obj@AbstractKS();
            obj.requests = requests;
            for ii = 1 : length( obj.requests )
                obj.reqHashs{ii} = AuditoryFrontEndKS.getRequestHash( obj.requests{ii} );
                obj.lastBlockEnd(ii) = 0;
            end
            %           example:
            %             requests{1}.name = 'modulation';
            %             requests{1}.params = genParStruct( ...
            %                 'nChannels', obj.amFreqChannels, ...
            %                 'am_type', 'filter', ...
            %                 'am_nFilters', obj.amChannels ...
            %                 );
            %             requests{2}.name = 'ratemap_magnitude';
            %             requests{2}.params = genParStruct( ...
            %                 'nChannels', obj.freqChannels ...
            %                 );
        end
        %% -------------------------------------------------------------------------------
        
        function delete( obj )
            %TODO: remove processors and handles in bb
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function afeSignals = getAFEdata( obj )
            afeSignals = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
            for ii = 1 : length( obj.requests )
                afeSignals(ii) = obj.blackboard.signals(obj.reqHashs{ii});
            end
        end
        %% -------------------------------------------------------------------------------

        function ens = hasEnoughNewSignal( obj, blockLen_s )
            ens = all( obj.blackboard.currentSoundTimeIdx - obj.lastBlockEnd >= blockLen_s );
        end
        %% -------------------------------------------------------------------------------

        function signalBlock = getSignalBlock( obj, sigId, blockTimes, padFront, padEnd )
            signalStream = obj.blackboard.signals(obj.reqHashs{sigId});
            backOffset = obj.blackboard.currentSoundTimeIdx - blockTimes(2);
            if backOffset < 0
                warning( 'BBS:badBlockTimeRequest', 'Requesting blocks ending in the future.' );
            end
            blockLen = blockTimes(2) - blockTimes(1);
            if ~iscell(signalStream), signalStream = {signalStream}; end
            signalBlock = cell(size(signalStream));
            for n = 1:numel(signalBlock)
                signalBlock{n} = signalStream{n}.getSignalBlock( blockLen, backOffset, padFront );
                if nargin >= 5 && padEnd
                    blocksize_samples = ceil( signalStream{n}.FsHz * blockLen );
                    if (size( signalBlock{n}, 1 ) < blocksize_samples)
                        signalBlock{n} = [signalBlock{n}; ...
                            zeros( blocksize_samples - size(signalBlock{n},1), ...
                            size(signalBlock{n},2), size(signalBlock{n},3) )];
                    end
                end
            end
            if numel(signalBlock) == 1, signalBlock = signalBlock{1}; end
            obj.lastBlockEnd(sigId) = blockTimes(2);
        end
        %% -------------------------------------------------------------------------------

        function signalBlock = getNextSignalBlock( obj, sigId, blockLen_s, shift_s, padFront, padEnd )
            if nargin < 4, shift_s = blockLen_s; end
            if nargin < 5, padFront = true; end
            if nargin < 6, padEnd = false; end
            blockTimes = [obj.lastBlockEnd(sigId)+shift_s-blockLen_s obj.lastBlockEnd(sigId)+shift_s];
            signalBlock = obj.getSignalBlock( sigId, blockTimes, padFront, padEnd );
        end
        %% -------------------------------------------------------------------------------

    end

end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
