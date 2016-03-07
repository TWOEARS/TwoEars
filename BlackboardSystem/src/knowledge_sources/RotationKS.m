classdef RotationKS < AbstractKS
    % RotationKS decides how much to rotate the robot head

    properties (SetAccess = private)
        rotationScheduled = false;    % To avoid repetitive head rotations
        robot;                        % Reference to a robot object
        rotationAngles = [20 -20]; % left <-- positive angles; negative angles --> right
        minRotationAngle = 10;        % minimum rotation angles
    end

    methods
        function obj = RotationKS(robot)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            obj.robot = robot;
            
            % Compute possible rotation angles
            % left <-- positive angles; negative angles --> right
            headOrientation = robot.getCurrentHeadOrientation;
            %rotationStep = robot.Sources{1}.IRDataset.AzimuthResolution;
            if isinf(robot.AzimuthMin)
                rotationRight = -80;
            else
                rotationRight = round(mod(robot.AzimuthMin-headOrientation, 360) - 360); % right: -78
            end
            if isinf(robot.AzimuthMax)
                rotationLeft = 80;
            else
                rotationLeft = round(mod(robot.AzimuthMax-headOrientation, 360)); % left: 78
            end
            %obj.rotationAngles = rotationRight:rotationStep:rotationLeft;
            
            % Force possible rotation angles
            obj.rotationAngles = obj.rotationAngles(obj.rotationAngles >= rotationRight ...
                & obj.rotationAngles <= rotationLeft);
            
            % Force a minimum rotation
            obj.rotationAngles = obj.rotationAngles(obj.rotationAngles >= obj.minRotationAngle ...
                | obj.rotationAngles <= -obj.minRotationAngle);
        end

        function setMinimumRotationAngle(obj, angle)
            obj.minRotationAngle = angle;
            obj.rotationAngles = obj.rotationAngles(obj.rotationAngles >= angle ...
                | obj.rotationAngles <= -angle);
            if isempty(obj.rotationAngles)
                error('Please check the minimum rotation as it causes head rotation angles to be empty');
            end
        end
        
        function setRotationAngles(obj, angles)
            obj.rotationAngles = angles;
            % Force a minimum rotation
            obj.rotationAngles = obj.rotationAngles(obj.rotationAngles >= obj.minRotationAngle ...
                | obj.rotationAngles <= -obj.minRotationAngle);
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

            confHyp = obj.blackboard.getData('confusionHypotheses', ...
                obj.trigger.tmIdx).data;
            [~,idx] = max(confHyp.sourcesDistribution);
            if confHyp.azimuths(idx) < 180
                % The most likely source is in the left plane, try turn the
                % head to the left
                headRotationAngles = obj.rotationAngles(obj.rotationAngles > 0);
            else
                headRotationAngles = obj.rotationAngles(obj.rotationAngles < 0);
            end
            
            % Randomly select a head rotation angle
            headRotateAngle = headRotationAngles(randi(length(headRotationAngles)));
            
            % Rotate head with a relative angle
            obj.robot.rotateHead(headRotateAngle, 'relative');


            %fprintf('head rotate about %d degrees. New head orientation: %.0f degrees\n', headRotateAngle, obj.robot.getCurrentHeadOrientation);
                      
                      
            bbprintf(obj, ['[RotationKS:] Commanded head to rotate about ', ...
                           '%d degrees. New head orientation: %.0f degrees\n'], ...
                          headRotateAngle, obj.robot.getCurrentHeadOrientation);
            
            obj.rotationScheduled = false;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
