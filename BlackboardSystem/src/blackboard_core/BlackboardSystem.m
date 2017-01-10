classdef BlackboardSystem < handle

    properties (SetAccess = private)
        blackboard;
        blackboardMonitor;
        scheduler;
        robotConnect;
        dataConnect;
        
        % ksVisualisers = containers.Map; % for visualising KSs
        locVis;     % for visualising localisation
        afeVis;     % for visualising AFE
        genderVis;     % for visualising gender recognition
    end

    methods

        %% System Construction
        function obj = BlackboardSystem( verbosity )
            if nargin<1, verbosity=0; end
            obj.blackboard = Blackboard( verbosity );
            obj.blackboardMonitor = BlackboardMonitor( obj.blackboard );
            obj.scheduler = Scheduler( obj.blackboardMonitor );
        end

        function setEnergyThreshold(obj, energyThreshold)
            obj.blackboard.setEnergyThreshold(energyThreshold);
        end
        
        % Set blackboard visualiser
        function setVisualiser(obj, visualiser)
            obj.scheduler.setVisualiser(visualiser);
        end
        
%         % Add a visualiser for a KS
%         function addKsVisualiser(obj, ksName, vis)
%             obj.ksVisualisers(ksName) = vis;
%         end
%         
%         % Set KS visualisers
%         function setKsVisualisers(obj, ksVisualisers)
%             obj.ksVisualisers = ksVisualisers;
%         end
        
        function setLocVis(obj, locVis)
            obj.locVis = locVis;
        end
        
        function setAfeVis(obj, afeVis)
            obj.afeVis = afeVis;
        end
        
        function setGenderVis(obj, genderVis)
            obj.genderVis = genderVis;
        end
        
        function setRobotConnect( obj, robotConnect )
            obj.robotConnect = robotConnect;
        end

        function setDataConnect( obj, connectorClassName, varargin )
            dataConnectArgs = [{obj.robotConnect} varargin];
            % Connect to the Two!Ears Auditory Front-End module
            obj.dataConnect = obj.createKS( connectorClassName, dataConnectArgs );
        end

        function createProcsForKs( obj, ks )
            % Create processes for the Two!Ears Auditory Front-End KS
            obj.dataConnect.createProcsForDepKS( ks );
        end

        %% From xml
        function buildFromXml( obj, xmlName )
            bbsXml = xmlread( xmlName);
            bbsXmlElements = bbsXml.getElementsByTagName( 'blackboardsystem' ).item(0);

            buildDataConnectFromXml( obj, bbsXmlElements );
            kss = buildKSsFromXml( obj, bbsXmlElements );
            buildConnectionsFromXml( obj, bbsXmlElements, kss );
        end

        function buildDataConnectFromXml( obj, bbsXmlElements )
            elements = bbsXmlElements.getElementsByTagName( 'dataConnection' );
            [ksType,ksConstructArgs] = obj.readKsXmlConstructArgs( elements.item(0) );
            obj.setDataConnect( ksType, ksConstructArgs{:} );
        end

        function kss = buildKSsFromXml( obj, bbsXmlElements )
            kss = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            ksElements = bbsXmlElements.getElementsByTagName( 'KS' );
            for k = 1:ksElements.getLength()
                ksName = char( ksElements.item(k-1).getAttribute('Name') );
                if kss.isKey( ksName )
                    error( '%s used twice as KS name!', ksName );
                end
                [ksType,ksConstructArgs] = obj.readKsXmlConstructArgs( ksElements.item(k-1) );
                kss(ksName) = obj.createKS( ksType, ksConstructArgs );
            end
        end
        
        function [ksType, ksParams] = readKsXmlConstructArgs( obj, ksXmlElement )
            ksType = char( ksXmlElement.getAttribute('Type') );
            ksParamElements = ksXmlElement.getChildNodes.getElementsByTagName('Param');
            ksParams = {};
            for jj = 1:ksParamElements.getLength()
                ksParamType = char( ksParamElements.item(jj-1).getAttribute('Type') );
                ksParamStr = char( ksParamElements.item(jj-1).getFirstChild.getData );
                switch ksParamType
                    case 'char'
                        ksParams{end+1} = ksParamStr;
                    case 'double'
                        ksParams{end+1} = str2double( ksParamStr );
                    case 'int'
                        ksParams{end+1} = int64( str2double( ksParamStr ) );
                    case 'ref'
                        ksParams{end+1} = obj.(ksParamStr);
                end
            end
        end

        function buildConnectionsFromXml( obj, bbsXmlElements, kss )
            connElements = bbsXmlElements.getElementsByTagName( 'Connection' );
            for k = 1:connElements.getLength()
                mode = char( connElements.item(k-1).getAttribute('Mode') );
                srcElements = ...
                    connElements.item(k-1).getChildNodes.getElementsByTagName('source');
                srcs = {};
                for jj = 1:srcElements.getLength()
                    srcName = char( srcElements.item(jj-1).getFirstChild.getData );
                    if kss.isKey( srcName )
                        srcs{end+1} = kss(srcName);
                    elseif isprop( obj, srcName )
                        srcs{end+1} = obj.(srcName);
                    else
                        error( ['Building connection: %s is not an existing ', ...
                                'source KS name!'], srcName );
                    end
                end
                snks = {};
                snkElements = ...
                    connElements.item(k-1).getChildNodes.getElementsByTagName('sink');
                for jj = 1:snkElements.getLength()
                    snkName = char( snkElements.item(jj-1).getFirstChild.getData );
                    if kss.isKey( snkName )
                        snks{end+1} = kss(snkName);
                    elseif isprop( obj, snkName )
                        snks{end+1} = obj.(snkName);
                    else
                        error( ['Building connection: %s is not an existing ', ...
                                'sink KS name!'], snkName );
                    end
                end
                bindParams = {srcs, snks, mode};
                evntName = char( connElements.item(k-1).getAttribute('Event') );
                if ~isempty( evntName )
                    bindParams{end+1} = evntName;
                end
                obj.blackboardMonitor.bind( bindParams{:} );
            end
        end

        %% Add KS to the blackboard system
        function ks = addKS( obj, ks )
            ks.setBlackboardAccess( obj.blackboard, obj );
            % using getfield to generate matlab error if class name changes.
            if isa( ks, getfield( ?AuditoryFrontEndDepKS, 'Name' ) )
                obj.createProcsForKs( ks );
            end
            obj.blackboard.KSs = [obj.blackboard.KSs {ks}];
        end

        %% Create and add KS to the blackboard system
        function ks = createKS( obj, ksClassName, ksConstructArgs )
            if nargin < 3, ksConstructArgs = {}; end;
            ks = feval( ksClassName, ksConstructArgs{:} );
            ks = obj.addKS( ks );
        end

        %% Get number of KSs
        function n = numKSs( obj )
            n = length( obj.blackboard.KSs );
        end


        %% List available AFE cues
        function listAfeData(obj)
            % Get AFE cues
            data = obj.dataConnect.managerObject.Data;
            % Get head rotations
            headOrientations = obj.blackboard.getData('headOrientation');
            fprintf(1, '\nAvailable AFE data:\n\n');
            fields = fieldnames(data);
            for ii = 1:length(fields)
                if iscell(getfield(data, fields{ii}))
                    fprintf(1, '  ''%s\''\n', fields{ii})
                end
            end
            if length(headOrientations)>0
                fprintf(1, '  ''head_rotation''\n')
            end
            fprintf(1, '\n');
        end

        %% Return AFE cues
        function cues = getAfeData(obj, name)
            if strcmp('head_rotation', name)
                cues = obj.blackboard.getData('headOrientation');
            else
                afeData = obj.dataConnect.managerObject.Data;
                cues = getfield(afeData, name);
            end
        end

        %% Plot AFE cues
        function plotAfeData(obj, name)
            cues = getAfeData(obj, name);
            if strcmp('head_rotation', name)
                % Get default plotting parameter from AFE
                p = Parameters.getPlottingParameters();
                figure;
                plot([cues.sndTmIdx], [cues.data]);
                xlabel('Time (s)', ...
                       'fontsize', p.map('fsize_label'), ...
                       'fontname', p.map('ftype'));
                ylabel('Head orientation (deg)', ...
                       'fontsize', p.map('fsize_label'), ...
                       'fontname', p.map('ftype'));
                title('Head rotation', ...
                      'fontsize', p.map('fsize_title'), ...
                      'fontname', p.map('ftype'));
                set(gca,'fontsize',p.map('fsize_axes'),'fontname',p.map('ftype'));
                axis([cues(1).sndTmIdx cues(end).sndTmIdx ...
                      0 360]);
            else % AFE cues
                if size(cues,2)==1
                    cues{1}.plot;
                elseif size(cues,2)==2
                    cues{1}.plot;
                    cues{2}.plot;
                else
                    error(['Your picked data has %i channels, only 1 or 2 ', ...
                           'are supported.']);
                end
            end
        end

        %% System Execution
        function run( obj )
            while obj.robotConnect.isActive()
                obj.scheduler.processAgenda();
                notify( obj.scheduler, 'AgendaEmpty' );
            end
        end

    end

end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
