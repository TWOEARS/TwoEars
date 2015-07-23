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
%             locHyp = obj.blackboard.getData('confusionHypotheses', ...
%                 obj.trigger.tmIdx).data;
%             [~,idx] = max(locHyp.posteriors);
%             maxAngle = locHyp.locations(idx);
%             if maxAngle <= 180
%                 headRotateAngle = maxAngle;
%             else
%                 headRotateAngle = maxAngle - 360;
%             end

            % Head will rotate towards the most dominant source while making
            % sure head orientation never stays out of [-30 30] so that Surrey 
            % database can be used. When the head cannot be rotated (either
            % is already facing the most dominant source or has reached the
            % Surrey head orientation boundary), a minimal 10 degree rotation
            % will be applied
            headOrientation = obj.blackboard.getData( ...
                'headOrientation', obj.trigger.tmIdx).data;
            locHyp = obj.blackboard.getData( ...
                'confusionHypotheses', obj.trigger.tmIdx).data;
            [~,idx] = max(locHyp.posteriors);
            mlAngle = locHyp.locations(idx);
            % Make sure a minimal head rotation
            minAngle = 5;
            if mlAngle == 0
                headRotateAngle = minAngle * sign(randn(1));
            elseif mlAngle < minAngle
                headRotateAngle = minAngle;
            elseif mlAngle > 360 - minAngle
                headRotateAngle = -minAngle;
            else
                if mlAngle <= 180
                    if mlAngle > 60
                        mlAngle = 60;
                    end
                    headRotateAngle = mlAngle;
                else
                    if mlAngle < 300
                        mlAngle = 300;
                    end
                    headRotateAngle = mlAngle - 360;
                end
            end

            newHO = mod(headOrientation + headRotateAngle, 360);
            if newHO > 30 && newHO <= 180
                headRotateAngle = 30 - headOrientation;
            elseif newHO < 330 && newHO > 180
                headRotateAngle = 330 - headOrientation;
            end

            if headRotateAngle >= 0 && (headOrientation == 30 || headOrientation == 25)
                headRotateAngle = -minAngle;
            elseif headRotateAngle <= 0 && (headOrientation == 330 || headOrientation == 335)
                headRotateAngle = minAngle;
            elseif headRotateAngle > 180
                headRotateAngle = headRotateAngle - 360;
            end

            % Rotate head with a relative angle
            obj.robot.rotateHead(headRotateAngle);

            if obj.blackboard.verbosity > 0
                fprintf('Commanded head to rotate about %d degrees. New head orientation: %.0f degrees\n', ...
                    headRotateAngle, obj.robot.getCurrentHeadOrientation);
            end
            obj.rotationScheduled = false;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
