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
            locHyp = obj.blackboard.getData('confusionHypotheses', ...
                obj.trigger.tmIdx).data;
            [~,idx] = max(locHyp.posteriors);
            maxAngle = locHyp.locations(idx);
            if maxAngle <= 180
                headRotateAngle = maxAngle;
            else
                headRotateAngle = maxAngle - 360;
            end

            % Rotate head with a relative angle
            obj.robot.rotateHead(headRotateAngle);

            if obj.blackboard.verbosity > 0
                fprintf('Commanded head to rotate about %d degrees\n', headRotateAngle);
            end
            obj.rotationScheduled = false;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
