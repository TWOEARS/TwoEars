classdef AuditoryFrontEndDepKS < AbstractKS
    % TODO: add description

    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        requests;       
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = AuditoryFrontEndDepKS( requests )
            obj = obj@AbstractKS();
            obj.requests = requests;
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
                reqHash = AuditoryFrontEndKS.getRequestHash( obj.requests{ii} );
                afeSignals(ii) = obj.blackboard.signals(reqHash);
            end
        end
        %% -------------------------------------------------------------------------------

    end

end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
