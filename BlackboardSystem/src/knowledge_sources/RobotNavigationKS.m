classdef RobotNavigationKS < AbstractKS
    % RobotNavigationKS
    %
    
    properties (SetAccess = private)
        movingScheduled = false;
        robot
        targetSource = [];
        robotPositions = [
            %95, 97.5; % Outside kitchen
            91, 98; % Kitchen
            %91, 102;  % Bed room
            87, 102]; % Living room
        idlocIdx = 0;
    end

    methods
        function obj = RobotNavigationKS(robot, targetSource)

            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            obj.robot = robot;
            
            if exist('targetSource', 'var')
                obj.targetSource = targetSource;
            else
                obj.targetSource = [];
            end
            
            obj.invocationMaxFrequency_Hz = 1;
        end

        function setTargetSource(obj, targetSource)
            obj.targetSource = targetSource;
        end

        function [bExecute, bWait] = canExecute(obj)
            bWait = false;
            bExecute = false;
            hyp = obj.blackboard.getLastData('singleBlockObjectHypotheses');
            if ~isempty(hyp)
                if ~isempty(obj.targetSource)
                    idloc = hyp.data;
                    idx = strcmp({idloc(:).label}, obj.targetSource);
                    if max(idx) > 0 && any(cell2mat({idloc(idx).p}) == 0.7) 
                        bExecute = true;
                        obj.idlocIdx =  argmax(cell2mat({idloc.p}));
                    end
                end
            end
        end

        function execute(obj)
            

            % Robot is not moving
            % Let us get it to move
            hyp = obj.blackboard.getLastData('singleBlockObjectHypotheses');
 
            idloc = hyp.data;
               
            % Now we have identified the target source. We want to
            % move the robot towards the source

            % idloc(idx).loc is source location relative to head
            targetLocBase = idloc(obj.idlocIdx).loc + obj.robot.getCurrentHeadOrientation;
            [posX, posY, theta] = obj.robot.getCurrentRobotPosition;
            nRobotPositions = size(obj.robotPositions,1);

            relativeAngles = zeros(nRobotPositions, 1);
            for idx = 1 : nRobotPositions
                currentTargetPos = obj.robotPositions(idx, :);
                relativeAngles(idx) = atan2d(currentTargetPos(2) - posY, ...
                    currentTargetPos(1) - posX); 
            end

            distances = 1 - cosd(relativeAngles - targetLocBase + theta*180/pi);
            [~, bestPosIdx] = min(distances);

            % Check if the target position is less than 1 metre away from
            % the current position and stay put if yes
            distMetres = sqrt((posX-obj.robotPositions(bestPosIdx,1))^2 + (posY-obj.robotPositions(bestPosIdx,2))^2);
            if distMetres > 1
                % Need to work out which angle to move to
                obj.robot.moveRobot(obj.robotPositions(bestPosIdx,1), obj.robotPositions(bestPosIdx,2), theta, 'absolute');
            end
            %obj.movingScheduled = true;
               
            notify(obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ));
        end
        
        % Visualisation
        function visualise(obj)

        end
        
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
