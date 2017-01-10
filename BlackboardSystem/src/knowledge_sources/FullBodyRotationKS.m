classdef FullBodyRotationKS < AbstractKS
    % HeadRotationKS decides how to rotate the robot head

    properties (SetAccess = private)
        rotationScheduled = false;    % To avoid repetitive head rotations
        robot;                        % Reference to a robot object
        minRotationAngle = 20;        % minimum rotation angles
        rotationScalingFactor = 0.5;
        headRotationLimits = [60, -60];
    end
    
    properties (Access = private)
        targetTorsoOrientation
        targetHeadOrientation
    end

    methods
        function obj = FullBodyRotationKS(robot)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            obj.robot = robot;
            obj.unfocus();
            
            % Assign current robot position and head orientation as 
            % starting points.
            [~, ~, obj.targetTorsoOrientation] = ...
                obj.robot.getCurrentRobotPosition();
            obj.targetHeadOrientation = obj.robot.getCurrentHeadOrientation;
        end

        function setMinimumRotationAngle(obj, angle)
            obj.minRotationAngle = angle;
        end
        
        function [b, wait] = canExecute(obj)
            b = false;
            wait = false;
            if ~obj.rotationScheduled
                b = true;
                obj.rotationScheduled = true;
            end
        end

        function execute(obj)
            % Get probabilistic output of localisation KS
            ploc = obj.blackboard.getData( ...
                'locationHypothesis', obj.trigger.tmIdx).data;
            
            % Compute circular mean.
            meanSourceDirection = atan2d( ...
                mean(ploc.sourcesPosteriors .* sind(wrapTo180(ploc.sourceAzimuths))), ...
                mean(ploc.sourcesPosteriors .* cosd(wrapTo180(ploc.sourceAzimuths))));
            
%             % Compute entropy of posterior distribution.
%             distEntropy = sum(ploc.sourcesPosteriors .* ...
%                 log2(ploc.sourcesPosteriors + eps));
            
            % Get current head orientation.
            currentHeadOrientation = obj.robot.getCurrentHeadOrientation;
            
            % Compute rotation angle.
            headRotateAngle = obj.rotationScalingFactor * ...
                (meanSourceDirection - currentHeadOrientation);
            newHeadOrientation = headRotateAngle + currentHeadOrientation;
            
            % Check if updated head orientation exceeds the specified
            % limits. If yes, a torso rotation will be carried out instead
            % and the head orientation will be reset to 0 degrees.
            if (newHeadOrientation >= obj.headRotationLimits(1)) || ...
                    (newHeadOrientation <= obj.headRotationLimits(2))
                if obj.hasTorsoRotationFinished()
                    [x, y, theta] = obj.robot.getCurrentRobotPosition();
                    newTorsoOrientation = wrapTo180(newHeadOrientation + theta);                    
                    
                    obj.robot.moveRobot(x, y, newTorsoOrientation, 'absolute');
                    obj.targetTorsoOrientation = newTorsoOrientation;
                end
            else
                if obj.hasHeadRotationFinished()
                    obj.robot.rotateHead(newHeadOrientation, 'absolute');
                    obj.targetHeadOrientation = newHeadOrientation;
                end
            end
           
            bbprintf(obj, ['[FullBodyRotationKS:] Commanded head to rotate about ', ...
                           '%d degrees. New head orientation: %.0f degrees\n'], ...
                          headRotateAngle, obj.robot.getCurrentHeadOrientation);
            
            obj.rotationScheduled = false;
        end
        
        function flag = hasTorsoRotationFinished(obj)
            [~, ~, currentTheta] = obj.robot.getCurrentRobotPosition();
            
            % Angular error margin of 5 degrees.
            if 1 - cosd(currentTheta - obj.targetTorsoOrientation) <= 0.0038
                flag = true;
            else
                flag = false;
            end
        end
        
        function flag = hasHeadRotationFinished(obj)
            % Angular error margin of 5 degrees.
            if 1 - cosd(obj.robot.getCurrentHeadOrientation - ...
                    obj.targetHeadOrientation) <= 0.0038
                flag = true;
            else
                flag = false;
            end
        end        
        
        % Visualisation
        function visualise(obj)
            if ~isempty(obj.blackboardSystem.locVis)
                obj.blackboardSystem.locVis.setHeadRotation(...
                    obj.robot.getCurrentHeadOrientation);
            end
        end
    end
end
