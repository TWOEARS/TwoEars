classdef JidoInterface < simulator.RobotInterface
    %JIDOINTERFACE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess = public, SetAccess = private)
        BlockSize               % Block size used by the audio stream 
                                % server in samples.
        SampleRate              % Sample rate of the audio stream server 
                                % in Hz.
        bIsFinished = false;    
        
        
        maxHeadLeft             % max head left turn
        maxHeadRight            % max head right turn
    end
    
    properties (Access = public)
        client                  % Handle to the genomix client.
        kemar                   % KEMAR control interface.
        jido                    % Jido interface.
        bass                    % Interface to the audio stream server.
    end
    
    properties (Access = private)
        headOrientation
        sampleIndex
    end
    
    methods (Access = public)
        function obj = JidoInterface(pathToGenomix)
            % JIDOINTERFACE Constructor...
            
            % Check if path to genomix is valid
            if ~exist(pathToGenomix, 'dir')
                error('Wrong path to genomix.');
            end
            
            % Add path to genomix
            userpath(pathToGenomix);
            
            % Set up genomix client
            obj.client = genomix.client('jido-base.laas.fr:8080');
            
            % Load KEMAR module
            obj.kemar = obj.client.load('kemar');
            
            % Load JIDO module
            obj.jido = obj.client.load('sendPosition');
            
            % Load BASS module
            obj.bass = obj.client.load('bass');
            
            % Get BASS status info
            audioObj = obj.bass.Audio();
            obj.SampleRate = audioObj.Audio.sampleRate;
            obj.BlockSize = audioObj.Audio.nFramesPerChunk * ...
                audioObj.Audio.nChunksOnPort;
            obj.sampleIndex = audioObj.Audio.lastFrameIndex;
            
            % Get KEMAR properties
            [obj.maxHeadLeft, obj.maxHeadRight] = getHeadTurnLimits(obj);
            obj.maxHeadLeft = obj.maxHeadLeft - rem(obj.maxHeadLeft,5);
            obj.maxHeadRight = obj.maxHeadRight - rem(obj.maxHeadRight,5);
            obj.headOrientation = obj.getCurrentHeadOrientation();
            
            % Set robot active
            obj.bActive = true;
        end
        
        
        function configureAudioStreamServer(obj, sampleRate, ...
                numFramesPerChunk, numChunksOnPort)
            % CONFIGUREAUDIOSTREAMSERVER
            
            % Check input arguments
            p = inputParser();
            
            p.addRequired('SampleRate', @(x) validateattributes(x, ...
                {'numeric'}, {'scalar', 'real'}));
            p.addRequired('NumFramesPerChunk', @(x) validateattributes(x, ...
                {'numeric'}, {'scalar', 'integer'}));
            p.addRequired('NumChunksOnPort', @(x) validateattributes(x, ...
                {'numeric'}, {'scalar', 'integer'}));
            p.parse(sampleRate, numFramesPerChunk, numChunksOnPort);
            
            % Setup audio stream server
            obj.bass.Acquire('-a', 'hw:1,0', p.Results.SampleRate, ...
                p.Results.NumFramesPerChunk, ...
                p.Results.NumChunksOnPort);
        end
        
        
        %% Grab binaural audio of a specified length
        function [earSignals, durSec, durSamples, orientationTrajectory] = ...
                getSignal(obj, durSec)
            %
            % Due to the frame-wise processing length of the output signal can
            % vary from the requested signal length
            %
            % Input Parameters
            %       durSec : length of signal in seconds @type double
            %
            % Output Parameters
            %          sig : audio signal [durSamples x 2]
            %       durSec : length of signal in seconds @type double
            %   durSamples : length of signal in samples @type integer
            
            % Read audio buffer
            audioBuffer = obj.bass.Audio();
            
            % Get binaural signals
            earSignals = [cell2mat(audioBuffer.Audio.left); ...
                cell2mat(audioBuffer.Audio.right)]';
            earSignals = earSignals ./ (2^31);
            
            % Get default buffer size of the audio stream server and
            % compute block size in samples.
            blockSizeSamples = round(durSec * obj.SampleRate);
            
            % Get difference of current time stamp.
            sampleDifference = audioBuffer.Audio.lastFrameIndex - ...
                obj.sampleIndex;
            obj.sampleIndex = audioBuffer.Audio.lastFrameIndex;
            
            if sampleDifference == 0
                error(['Zero sample difference. Please check if ', ...
                    'BASS is running correctly.']);
            end
            
            % Get truncated signals as new signal block.
            signalLengthSamples = min(sampleDifference, ...
                blockSizeSamples);
            earSignals = earSignals(end - signalLengthSamples + 1 : end, :);
            
            % Get signal length
            durSamples = size(earSignals, 1);
            durSec = durSamples / obj.SampleRate;
            
            % Interpolate head orientation within frame.
            orientationTrajectory = linspace(obj.headOrientation, ...
                obj.getCurrentHeadOrientation(), durSamples);
            obj.headOrientation = obj.getCurrentHeadOrientation();
        end
  
        
        %% Rotate the head with mode = {'absolute', 'relative'}
        function rotateHead(obj, angleDeg, mode)
        %
        % 1) mode = ?absolute?
        %    Rotate the head to an absolute angle relative to the base
        %      0/ 360 degrees = dead ahead
        %     90/-270 degrees = left
        %    -90/ 270 degrees = right
        %
        % 2) mode = ?relative?
        %    Rotate the head by an angle in degrees
        %    Positive angle = rotation to the left
        %    Negative angle = rotation to the right
        %
        % Head turn will stop when maxLeftHead or maxRightHead is reached
        %
        % Input Parameters
        %     angleDeg : rotation angle in degrees
        %         mode : 'absolute' or 'relative'

            % Execute motion command depending on selected mode
            switch lower(mode)
                case 'absolute'
                    absoluteAngle = wrapTo180(angleDeg);
                    
                case 'relative'
                    % Get current head position.
                    headAngle = obj.getCurrentHeadOrientation();
                    absoluteAngle = wrapTo180(headAngle + angleDeg);
                    
                otherwise
                    error('Mode %s not supported.', mode);
            end
            
            % Check turn limits
            if absoluteAngle > obj.maxHeadLeft
                absoluteAngle = obj.maxHeadLeft;
            elseif absoluteAngle < obj.maxHeadRight
                absoluteAngle = obj.maxHeadRight;
            end

            obj.kemar.MoveAbsolutePosition('-a', absoluteAngle);
        end
        
        
        %% Get the head orientation relative to the base orientation
        function azimuth = getCurrentHeadOrientation(obj)
        %
        % Output Parameters
        %      azimuth : head orientation in degrees
        %                 0 degrees = dead ahead
        %                90 degrees = left
        %               -90 degrees = right

            % Get current state of the KEMAR head
            kemarState = obj.kemar.currentState();
            azimuth = kemarState.currentState.position;
        end
        
        
        %% Get the maximum head orientation relative to the base orientation
        function [maxLeft, maxRight] = getHeadTurnLimits(obj)
        %
        % Output Parameters
        %      maxLeft  : maximum possible head orientation (90)
        %      maxRight : mimimum possible head orientation (-90)
        
            kemarState = obj.kemar.currentState();
            maxLeft = kemarState.currentState.maxLeft;
            maxRight = kemarState.currentState.maxRight;
        end
        
        
        %% Move the robot to a new position
        function moveRobot(obj, posX, posY, theta, mode)
        %
        % All coordinates are in the world frame
        %     0/ 360 degrees = positive x-axis
        %    90/-270 degrees = positive y-axis
        %   180/-180 degrees = negative x-axis
        %   270/- 90 degrees = negative y-axis
        %
        % Input Parameters
        %         posX : x position
        %         posY : y position
        %        theta : robot base orientation in the world frame
        %         mode : 'absolute' or 'relative'
        
            % Execute motion command depending on selected mode
            switch mode
                case 'absolute'
                    obj.jido.moveAbsolutePosition('/map', posX, posY, theta);
                case 'relative'
                    obj.jido.moveRelativePosition('/map', posX, posY, theta);
                otherwise
                    error('Mode %s not supported.', mode);
            end
        end
        

        %% Get the current robot position
    	function [posX, posY, theta] = getCurrentRobotPosition(obj)
        %
        % All coordinates are in the world frame
        %     0/ 360 degrees = positive x-axis
        %    90/-270 degrees = positive y-axis
        %   180/-180 degrees = negative x-axis
        %   270/- 90 degrees = negative y-axis
        %
        % Output Parameters
        %         posX : x position
        %         posY : y position
        %        theta : robot base orientation in the world frame
        
            p = obj.jido.NavigationState();
            posX = p.NavigationState.position.x;
            posY = p.NavigationState.position.y;
            theta = p.NavigationState.position.orientation;
        end
        
        %% Returns the current state of the robot navigation system
        function [message, statusId] = getNavigationState(obj)
            navigationState = obj.jido.NavigationState();
            message = navigationState.NavigationState.goal.text;
            statusId = navigationState.NavigationState.goal.status;
        end
        
        
        %% Returns true if robot is active
        function b = isActive(obj)
            b = obj.bActive;
        end
        
        
        %% 
        function delete(obj)
            % DELETE Destructor
            
            % Shut down the audio stream server
            delete(obj.bass);
            clear obj.bass;
            
            % Disconnect and shut down Jido interface
            delete(obj.jido);
            clear obj.jido;
            
            % Disconnect and shut down KEMAR interface
            delete(obj.kemar);
            clear obj.kemar;
            
            % Shut down genomix client
            delete(obj.client);
            clear obj.client;
        end
        

    end
end

