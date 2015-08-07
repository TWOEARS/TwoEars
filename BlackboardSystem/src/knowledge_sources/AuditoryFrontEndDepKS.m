classdef AuditoryFrontEndDepKS < AbstractKS
    % TODO: add description

    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        requests;       
        reqHashs;
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = AuditoryFrontEndDepKS( requests )
            obj = obj@AbstractKS();
            obj.requests = requests;
            for ii = 1 : length( obj.requests )
                obj.reqHashs{ii} = AuditoryFrontEndKS.getRequestHash( obj.requests{ii} );
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

    end

end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
