classdef RotationKS < AbstractKS
    % RotationKS decides how much to rotate the robot head

    properties (SetAccess = private)
        rotationScheduled = false;    % To avoid repetitive head rotations
        robot;                        % Reference to a robot object
    end

    methods
        function obj = RotationKS(robot)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            obj.robot = robot;
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

            % Workout the head rotation angle so that the head will face
            % the most likely source location.
            % For some impulse responses like BRIR the possible head rotations might be
            % limited. Those maximum values of possible head rotation are accessable from
            % the robot.
            %
            % Set head rotation to the point of most likely perceived source direction
            locHyp = obj.blackboard.getData('confusionHypotheses', ...
                obj.trigger.tmIdx).data;
            [~,idx] = max(locHyp.posteriors);
            perceivedAngle = locHyp.locations(idx);
            if perceivedAngle <= 180
                headRotateAngle = perceivedAngle;
            else
                headRotateAngle = perceivedAngle - 360;
            end
            % Ensure minimal head rotation
            minAngle = 3;
            if abs(headRotateAngle)<minAngle
                headRotateAngle = sign(randn(1)) * minAngle;
            end
            % Ensure head rotation is possible and add some jitter if maximum is
            % approached
            headOrientation = obj.blackboard.getData( ...
               'headOrientation', obj.trigger.tmIdx).data;
            maxLimitHeadRotation = obj.robot.AzimuthMax - headOrientation;
            minLimitHeadRotation = obj.robot.AzimuthMin - headOrientation;
            if headRotateAngle > maxLimitHeadRotation
                headRotateAngle = round(maxLimitHeadRotation - 5*rand);
            elseif headRotateAngle < minLimitHeadRotation
                headRotateAngle = round(minLimitHeadRotation + 5*rand);
            end

            % Rotate head with a relative angle
            obj.robot.rotateHead(headRotateAngle, 'relative');

            if obj.blackboard.verbosity > 0
                fprintf(['--%05.2fs [Rotation KS:] Commanded head to rotate about ', ...
                         '%d degrees. New head orientation: %.0f degrees\n'], ...
                        obj.trigger.tmIdx, headRotateAngle, ...
                        obj.robot.getCurrentHeadOrientation);
            end
            obj.rotationScheduled = false;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
