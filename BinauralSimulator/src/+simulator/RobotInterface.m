classdef (Abstract) RobotInterface < matlab.mixin.SetGet
  % Abstract class for the robot interface
  
    methods (Abstract)
        
        %% Grab binaural audio of a specified length
        [sig, durSec, durSamples] = getSignal(obj, durSec)
        % function [sig, durSec, durSamples] = getSignal(obj, durSec)
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
        %

  
        %% Rotate the head with mode = {'absolute', 'relative'}
        rotateHead(obj, angleDeg, mode)
        % function rotateHead(obj, angleDeg, mode)
        %
        % 1) mode = 'absolute'
        %    Rotate the head to an absolute angle relative to the base
        %      0/ 360 degrees = dead ahead
        %     90/-270 degrees = left
        %    -90/ 270 degrees = right
        %
        % 2) mode = 'relative'
        %    Rotate the head by an angle in degrees
        %    Positive angle = rotation to the left
        %    Negative angle = rotation to the right
        %
        % Head turn will stop when maxLeftHead or maxRightHead is reached
        %
        % Input Parameters
        %     angleDeg : rotation angle in degrees
        %         mode : 'absolute' or 'relative'
        %
    
        
        %% Get the head orientation relative to the base orientation
        azimuth = getCurrentHeadOrientation(obj)
        % function azimuth = getCurrentHeadOrientation(obj)
        %
        % Output Parameters
        %      azimuth : head orientation in degrees
        %                 0 degrees = dead ahead
        %                90 degrees = left
        %               -90 degrees = right
        %
        
        %% Get the maximum head orientation relative to the base orientation
        [maxLeft, maxRight] = getHeadTurnLimits(obj)
        % function [maxLeft, maxRight] = getHeadTurnLimits(obj)
        %
        % Output Parameters
        %      maxLeft  : maximum possible head orientation
        %      maxRight : mimimum possible head orientation
        
        %% Move the robot to a new position
        moveRobot(obj, posX, posY, theta, mode)
        % function moveRobot(obj, posX, posY, theta, mode)
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
        %

    
        %% Get the current robot position
        [posX, posY, theta] = getCurrentRobotPosition(obj)
        % function [posX, posY, theta] = getCurrentRobotPosition(obj)
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
        
        
        %% Returns true if robot is active
        b = isActive(obj)
        % function b = isActive(obj)
        
    end
    
    properties
        bActive = false;
    end
    
    methods
        %% Stopping the robot will cause isActive() to return false
        function stop(obj)
            obj.bActive = false;
        end
        
        function start(obj)
            obj.bActive = true;
        end
    end

end
