classdef HeadRotationKS < AbstractKS
    % HeadRotationKS decides how to rotate the robot head

    properties (SetAccess = private)
        rotationScheduled = false;    % To avoid repetitive head rotations
        robot;                        % Reference to a robot object
        %rotationAngles = [20 -20]; % left <-- positive angles; negative angles --> right
        minRotationAngle = 20;        % minimum rotation angles
    end

    methods
        function obj = HeadRotationKS(robot)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            obj.robot = robot;
            obj.unfocus();
        end

        function setMinimumRotationAngle(obj, angle)
            obj.minRotationAngle = angle;
        end
        
%         function setRotationAngles(obj, angles)
%             obj.rotationAngles = angles;
%             % Force a minimum rotation
%             obj.rotationAngles = obj.rotationAngles(obj.rotationAngles >= obj.minRotationAngle ...
%                 | obj.rotationAngles <= -obj.minRotationAngle);
%         end
        
        function [b, wait] = canExecute(obj)
            b = false;
            wait = false;
            if ~obj.rotationScheduled
                b = true;
                obj.rotationScheduled = true;
            end
        end

        function execute(obj)

            % Get the most likely source direction
            ploc = obj.blackboard.getData( ...
                'locationHypothesis', obj.trigger.tmIdx).data;
            [post,idx] = max(ploc.sourcesDistribution);
            % confHyp.azimuths are relative to the current head orientation
            azSrc = wrapTo180(ploc.azimuths(idx));
            
            % We want to turn the head toward the most likely source
            % direction, but if not a strong source, make a random rotation
            if post < 0.3
                if rand(1) < 0.5
                    azSrc = obj.minRotationAngle;
                else
                    azSrc = -obj.minRotationAngle;
                end
            end
            
            if azSrc > 0
                % Source is at the left side of current head orientation
                headRotateAngle = obj.minRotationAngle;
            else
                % Source is at the right side
                headRotateAngle = -obj.minRotationAngle;
            end
            
            if post < 0.1
                headRotateAngle = 0;
            end
            
            % Always make sure the head stays in the head turn limits
            [maxLeft, maxRight] = obj.robot.getHeadTurnLimits; 
            newHO = headRotateAngle + obj.robot.getCurrentHeadOrientation;
            if newHO >= maxLeft || newHO <= maxRight
                headRotateAngle = -headRotateAngle;
            end

            % Rotate head with a relative angle
            obj.robot.rotateHead(headRotateAngle, 'relative');

            bbprintf(obj, ['[HeadRotationKS:] Commanded head to rotate about ', ...
                           '%d degrees. New head orientation: %.0f degrees\n'], ...
                          headRotateAngle, obj.robot.getCurrentHeadOrientation);
            
            obj.rotationScheduled = false;
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

% vim: set sw=4 ts=4 et tw=90 cc=+1:
