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

            % Randomly select a head rotation angle but make sure head 
            % orientation stays inside [-30 30] for the Surrey database
            rotationAngles = [60:-5:10 -10:-5:-60];
            headOrientation = obj.blackboard.getData( ...
               'headOrientation', obj.trigger.tmIdx).data;
            while true
                headRotateAngle = rotationAngles(randi(length(rotationAngles)));
                newHO = mod(headOrientation + headRotateAngle, 360);
                if newHO <= 30 || newHO >= 330
                    break;
                end
            end
            % Rotate head with a relative angle
            obj.robot.rotateHead(headRotateAngle, 'relative');

            bbprintf(obj, ['[RotationKS:] Commanded head to rotate about ', ...
                           '%d degrees. New head orientation: %.0f degrees\n'], ...
                          headRotateAngle, obj.robot.getCurrentHeadOrientation);

            obj.rotationScheduled = false;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
