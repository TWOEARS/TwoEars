% Simple class to visualise blackboard activities
% NM 21/09/2016

classdef VisualiserBlackboard < handle
    
    properties (SetAccess = private)
        ksColourMap = containers.Map; % KS colour map
        drawHandle; % draw handle
        
        bubbleHandle;
        bubbleLabelHandle;
        bbMaxWidth = 4;
        bbMinWidth = 1.5;
        bbHeight = 0.8;
        labelOffset = 0.15;
        numBubbles = 20;
        bubbleIndex = 0;    % New bubble index
        
        colourList = [0.4660    0.6740    0.1880
                      0.8500    0.3250    0.0980
                      0.0000    0.4470    0.7410
                      0.9290    0.6940    0.1250
                      0.3010    0.7450    0.9330
                      0.6350    0.0780    0.1840
                      0.4940    0.1840    0.5560];
        colourIndex = 1;
    end
    
    methods
        
        function obj = VisualiserBlackboard(drawHandle)
            if nargin < 1
                figure('color',[1 1 1]);
                obj.drawHandle = gca;
            else
                obj.drawHandle = drawHandle;
            end
            
            axes(obj.drawHandle);
            obj.reset;
        end
        
        function reset(obj)
            
            obj.bubbleIndex = 0;
            obj.colourIndex = 1;
            obj.ksColourMap = containers.Map;
            
            axes(obj.drawHandle);
            cla
            hold on;
            box on;
            axis off;

            % Set axis
            axis([0 obj.bbMaxWidth+0.1 0 obj.numBubbles-0.2]);
            
            %set(obj.drawHandle,'xtick',[],'ytick',obj.yMin:obj.yMin+obj.yHeight,'yticklabel',0:obj.yHeight);
            %ylabel('Time [sec]');
            %set(obj.drawHandle,'XLimMode', 'manual', 'YLimMode', 'manual');
            
            [obj.bubbleHandle, obj.bubbleLabelHandle] = deal(zeros(obj.numBubbles, 1));
            for n = 1:obj.numBubbles
                %cIdx = mod(n, 7); if cIdx==0; cIdx=7; end
                %bbWidth = randi((obj.bbMaxWidth-obj.bbMinWidth)*10)/10 + obj.bbMinWidth;
                %bbXpos = obj.bbMaxWidth-bbWidth;
                obj.bubbleHandle(n) = rectangle('Position', [0 n-1 0 obj.bbHeight],...
                                    'Curvature', 1, ...
                                    'FaceColor', 'none', ...
                                    'EdgeColor', 'none');
                obj.bubbleLabelHandle(n) = text(obj.labelOffset, n-0.6, ...
                    '', 'FontSize', 11, ...
                    'FontWeight', 'bold', 'Color', [1 1 1]);
            end
            
        end
        
        function idx = downBubbleIndex(obj, idx)
            idx = idx - 1;
            if idx < 1
                idx = obj.numBubbles;
            end
        end
        
        function idx = upBubbleIndex(obj, idx)
            idx = idx + 1;
            if idx > obj.numBubbles
                idx = 1;
            end
        end
        
        function moveUp(obj, idx)
            h = obj.bubbleHandle(idx);
            pos = get(h, 'Position');
            pos(2) = pos(2) + 1;
            set(h, 'Position', pos);
            
            h = obj.bubbleLabelHandle(idx);
            pos = get(h, 'Position');
            pos(2) = pos(2) + 1;
            set(h, 'Position', pos);
        end
        
        function addKS(obj, ksLabel)
            
            % Move all bubbles up except the top one
            if obj.bubbleIndex > 0
                idx = obj.bubbleIndex;
                for n=1:obj.numBubbles-1
                    obj.moveUp(idx);
                    idx = obj.upBubbleIndex(idx);
                end
                % Update new bubble index
                obj.bubbleIndex = obj.downBubbleIndex(obj.bubbleIndex);
            else
                obj.bubbleIndex = 1;
            end
            
            
            % Get a colour for the new KS
            if obj.ksColourMap.isKey(ksLabel)
                % If we've seen this KS, try to use the same colour
                colour = obj.colourList(obj.ksColourMap(ksLabel),:);
            else
                % Get a new colour
                obj.ksColourMap(ksLabel) = obj.colourIndex;
                colour = obj.colourList(obj.colourIndex,:);
                obj.colourIndex = obj.colourIndex + 1;
                if obj.colourIndex > size(obj.colourList, 1)
                    obj.colourIndex = 1;
                end
            end
            
            % Set colour and default size to bbMinWidth
            bbXpos = obj.bbMaxWidth-obj.bbMinWidth;
            set(obj.bubbleHandle(obj.bubbleIndex), ...
                'Position', [bbXpos 0 obj.bbMinWidth obj.bbHeight], ...
                'FaceColor', colour);
            set(obj.bubbleLabelHandle(obj.bubbleIndex), ...
                'Position', [bbXpos+obj.labelOffset 0.4 0], ...
                'String', ksLabel);
        end
        
        % Set duration in sec of the latest KS
        function setKsDuration(obj, ksLabel, dur)
            
            str = sprintf('%s (%.0f msec)', ksLabel, dur*1000);
            
            % Map duration in seconds to bubble width
            minDur = 0.005;
            if dur < minDur 
                dur = minDur;
            end
            % Compress dur to a value between 0 and 1
            bbWidth = (1/(1+exp(-10*(dur-minDur))) - 0.5) * 2;
            % Convert to a value between bbMinWidth and bbMaxWidth
            bbWidth = bbWidth * (obj.bbMaxWidth - obj.bbMinWidth) + obj.bbMinWidth;

            % Update position and duration 
            bbXpos = obj.bbMaxWidth-bbWidth;
            set(obj.bubbleHandle(obj.bubbleIndex), ...
                'Position', [bbXpos 0 bbWidth obj.bbHeight]);
            set(obj.bubbleLabelHandle(obj.bubbleIndex), ...
                'Position', [bbXpos+obj.labelOffset 0.4 0], ...
                'String', str);
            
            drawnow;
        end
        
    end
end
