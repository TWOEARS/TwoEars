classdef BRIRsource < SceneConfig.SourceBase & Parameterized

    %% -----------------------------------------------------------------------------------
    properties
        brirFName;
        speakerId;
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = BRIRsource( brirFName, varargin )
            pds{1} = struct( 'name', 'speakerId', ...
                             'default', [], ...
                             'valFun', @(x)(isnumeric(x)) );
            obj = obj@Parameterized( pds );
            obj = obj@SceneConfig.SourceBase( varargin{:} );
            obj.brirFName = strrep( brirFName, '\', '/' );
        end
        %% -------------------------------------------------------------------------------
        
        function e = isequal( obj1, obj2 )
            f1SepIdxs = strfind( obj1.brirFName, '/' );
            f2SepIdxs = strfind( obj2.brirFName, '/' );
            e = isequal@SceneConfig.SourceBase( obj1, obj2 ) && ...
                isequal( obj1.speakerId, obj2.speakerId ) && ...
                strcmp( obj1.brirFName(f1SepIdxs(end-1):end), obj2.brirFName(f2SepIdxs(end-1):end) );
        end
        %% -------------------------------------------------------------------------------
                
    end
    
end
