classdef IdEvalFrame < handle
    
    properties (SetAccess = private)
        bb;
        idError;
        idTruth;
    end
    
    methods
        
        function obj = IdEvalFrame( blackboard )
            obj.bb = blackboard;
        end
        
        function readIdTruth( obj, sourceWavName, zeroOffsetLength_s )
            obj.idTruth.class = IdEvalFrame.readEventClass( sourceWavName );
            obj.idTruth.onsetsOffsets = ...
                IdEvalFrame.readOnOffAnnotations( sourceWavName ) + zeroOffsetLength_s;
            obj.idTruth.onsetsOffsets(obj.idTruth.onsetsOffsets(:,1) == inf,:) = [];
            obj.idTruth.onsetsOffsets(obj.idTruth.onsetsOffsets(:,2) == inf,:) = [];
        end

        function setIdTruth( obj, idTruth )
            obj.idTruth.class = idTruth.class;
            obj.idTruth.onsetsOffsets = idTruth.onsetsOffsets;
        end
        
        function ide = calcIdError( obj )
            idDecs = obj.bb.getData( 'identityDecision' );
            idDecs = idDecs(arrayfun(@(x)(strcmp(x.data.label,obj.idTruth.class)),idDecs));
            if ~isempty( idDecs )
                iddTm = [idDecs.sndTmIdx];
                iddDat = [idDecs.data];
                iddOnOffs = [(iddTm - [iddDat.concernsBlocksize_s]); iddTm]';
            else
                iddOnOffs = zeros(0,2);
            end
            k = 1;
            while k < size( iddOnOffs, 1 )
                if iddOnOffs(k,2) >= iddOnOffs(k+1,1)
                    iddOnOffs(k,2) = iddOnOffs(k+1,2);
                    iddOnOffs(k+1,:) = [];
                else
                    k = k + 1;
                end
            end
            
            ide.time.testpos = sum( iddOnOffs(:,2) - iddOnOffs(:,1) );
            ide.time.testneg = obj.bb.currentSoundTimeIdx - ide.time.testpos;
            ide.time.condpos = sum( obj.idTruth.onsetsOffsets(:,2) - obj.idTruth.onsetsOffsets(:,1) );
            ide.time.condneg = obj.bb.currentSoundTimeIdx - ide.time.condpos;
            ide.time.truepos = 0;
            for k = 1:size(iddOnOffs,1)
                intersectOffs = min( iddOnOffs(k,2), obj.idTruth.onsetsOffsets(:,2) );
                intersectOns = max( iddOnOffs(k,1), obj.idTruth.onsetsOffsets(:,1) );
                overlaps = max( 0, intersectOffs - intersectOns );
                ide.time.truepos = ide.time.truepos + sum( overlaps );
            end
            ide.time.trueneg = ide.time.condneg - ide.time.testpos + ide.time.truepos;
            ide.time = IdEvalFrame.meanErrors( ide.time );
            
            ide.blocks.condpos = 0;
            ide.blocks.condneg = 0;
            ide.blocks.testpos = 0;
            ide.blocks.truepos = 0;
            ide.blocks.testneg = 0;
            ide.blocks.trueneg = 0;
            idHyps = obj.bb.getData( 'identityHypotheses' );
            for idHyp = idHyps
                endBlockTime = idHyp.sndTmIdx;
                startBlockTime = endBlockTime - idHyp.data(1).concernsBlocksize_s;
                blockInclEvent = ...
                    ( sum( (obj.idTruth.onsetsOffsets(:,1) <= endBlockTime) ...
                            == (obj.idTruth.onsetsOffsets(:,2) >= endBlockTime) ) ...
                    + sum( (obj.idTruth.onsetsOffsets(:,1) <= startBlockTime) ...
                            == (obj.idTruth.onsetsOffsets(:,2) >= startBlockTime) ) ...
                    + sum( (obj.idTruth.onsetsOffsets(:,1) >= startBlockTime) ...
                            == (obj.idTruth.onsetsOffsets(:,2) <= endBlockTime) ) )...
                    >= 1;
                ide.blocks.condpos = ide.blocks.condpos + blockInclEvent;
                ide.blocks.condneg = ide.blocks.condneg + ~blockInclEvent;

                idDec = obj.bb.getData( 'identityDecision', idHyp.sndTmIdx );
                if ~isempty( idDec ) && strcmpi( obj.idTruth.class, idDec.data.label )
                    ide.blocks.testpos = ide.blocks.testpos + 1;
                    ide.blocks.truepos = ide.blocks.truepos + blockInclEvent;
                else
                    ide.blocks.testneg = ide.blocks.testneg + 1;
                    ide.blocks.trueneg = ide.blocks.trueneg + ~blockInclEvent;
                end
            end
            ide.blocks = IdEvalFrame.meanErrors( ide.blocks );
            
            obj.idError = ide;
        end
    end
    
    %% Static utils
    methods (Static)
        
        function eventClass = readEventClass( soundFileName )
            fileSepPositions = sort([strfind( soundFileName, '/' ) ...
                                     strfind( soundFileName, '\' )]);
            if isempty( fileSepPositions )
                error( 'Cannot infer sound event class - possibly because "%s" is not a path.', soundFileName );
            end
            classPos1 = fileSepPositions(end-1);
            classPos2 = fileSepPositions(end);
            eventClass = soundFileName(classPos1+1:classPos2-1);
        end
        
        function [onsetOffsets,types] = readOnOffAnnotations( soundFileName, isAbsPath )
            if nargin < 2
                isAbsPath = false;
            end
            if ~isAbsPath
                soundFileName = getPathPart( soundFileName, 'sound_databases' );
            end
            annotFid = -1;
            try
                annotFid = fopen( db.getFile([soundFileName '.txt']) );
            catch err
                warning( err.message );
            end
            onsetOffsets = zeros(0,2);
            types = {};
            if annotFid ~= -1
                while 1
                    annotLine = fgetl( annotFid );
                    if ~ischar( annotLine ), break, end
                    onsetOffsets(end+1,:) = zeros(1,2);
                    [on,b] = strtok( annotLine );
                    onsetOffsets(end,1) = str2double( on );
                    [off,t] = strtok( b );
                    types{end+1} = strtrim( t );
                    onsetOffsets(end,2) = str2double( off );
                end
                fclose( annotFid );
            else
                warning( sprintf( 'label annotation file not found: %s.txt. Assuming no events.', soundFileName ) );
            end
        end
        
        function errors = meanErrors( errors )
            errors(1).truepos = sum([errors.truepos]);
            errors(1).condpos = sum([errors.condpos]);
            errors(1).condneg = sum([errors.condneg]);
            errors(1).testpos = sum([errors.testpos]);
            errors(1).trueneg = sum([errors.trueneg]);
            errors(1).testneg = sum([errors.testneg]);
            errors(2:end) = [];
            errors.sensitivity = errors.truepos / errors.condpos;
            errors.pospredval = errors.truepos / errors.testpos;
            errors.specificity = errors.trueneg / errors.condneg;
            errors.negpredval = errors.trueneg / errors.testneg;
            errors.acc = (errors.truepos + errors.trueneg) / ...
                (errors.condpos + errors.condneg);
        end
        
    end
    
end
