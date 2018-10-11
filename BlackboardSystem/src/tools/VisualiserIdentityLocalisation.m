% Simple class to visualise sound localisation
% Assumed that vector of posterior probabilties is given, scaled in range
% [0,1]
% Head rotation can also be updated
% Example:
% v = VisualiserLocalisation(72);       % initialise for 72 angles
% v = v.setPosteriors(rand(1,72));      % set prob of each angle to random
% v = v.setHeadRotation(45);            % rotate head to 45 degrees (RHR)
% v = v.setHue(30);                     % set the hue to 30 degres
% v = v.setScaleFactor(1.5);            % set scale factor to 1.5
% GJB 13/5/2016
%
% NM 21/09/2016: a few bug fixes

classdef VisualiserIdentityLocalisation < handle
    
    properties(Constant)
        INNER_RADIUS = 175;
        OUTER_RADIUS = 300;
        MARKER_RADIUS = 620;
        LINE_WIDTH = 8.0;
        SHOW_GRID = true;
        NUM_GRID_LINES = 36;
    end
    
    properties (SetAccess = private)
        ksColourMap = containers.Map; % identity colour map
        idRadiusMap = containers.Map; % identity radius map
        radiusList = -250:35:200;
        colourList = [0.4660    0.6740    0.1880
                      0.8500    0.3250    0.0980
                      0.0000    0.4470    0.7410
                      0.9290    0.6940    0.1250
                      0.3010    0.7450    0.9330
                      0.6350    0.0780    0.1840
                      0.4940    0.1840    0.5560];
        colourIndex = 1;
        radiusIndex = 1;
        Angles
        Posteriors
        HeadRotationDegrees = 0
        NumPosteriors = 72
        drawHandle
        HeadHandle
        TextHandle
        MarkerHandle
        MarkerTextHandle
        MarkerHandles
        BarHandle
        TextHandles
        idTextHandles
        Hue = 50 % hue in HSV space, default is orangey yellow
        ScaleFactor = 2
        tmIdx = -1
        locations
        probabilities
    end
    
    methods
        
        function obj = VisualiserIdentityLocalisation(drawHandle)
            if nargin>0
                obj.drawHandle = drawHandle;
            else
                figure('Color',[1 1 1]);
                obj.drawHandle = gca;
            end
            obj.BarHandle = zeros(1,obj.NumPosteriors);
            obj.reset();
            obj.locations = [];
            obj.probabilities = [];
        end
        
        function reset(obj)
            obj.radiusIndex = 1;
            obj.colourIndex = 1;
            axes(obj.drawHandle);
            
            obj.ksColourMap = containers.Map;
            obj.idRadiusMap = containers.Map;
            cla;
            x=sin(linspace(0,2*pi,50));
            y=cos(linspace(0,2*pi,50));
            c=[0.9 0.9 0.9];
            hold on;
            
            % add a grid if required
            if (obj.SHOW_GRID)
                for ii=1:obj.NUM_GRID_LINES
                    angle_degrees = wrapTo180((ii-1)*360/obj.NUM_GRID_LINES);
                    angle_rad = -2*pi*angle_degrees/360;
                    sn = sin(angle_rad); cs = cos(angle_rad);
                    plot([obj.INNER_RADIUS*sn 520*sn],[obj.INNER_RADIUS*cs 520*cs],'Color',c);
                    text(560*sn,560*cs,num2str(angle_degrees),'HorizontalAlignment','Center','Color',[0.7 0.7 0.7]);
                end
                % circles
                for ii=0:4
                    r=obj.INNER_RADIUS+ii*(500-obj.INNER_RADIUS)/4;
                plot(r*sin(linspace(0,2*pi,50)),r*cos(linspace(0,2*pi,50)),'Color',c);
                end
            end
            
            % add head
            h1 = fill(-90+20*x,40*y,c);
            h2 = fill(90+20*x,40*y,c);
            h3 = fill([-30 30 0 -30],[90 90 130 90],c);
            h4 = fill(90*x,100*y,c);
            h5 = line([0 0],[-20 20],'Color',[0.8 0.8 0.8]);
            h6 = line([-20 20],[0 0],'Color',[0.8 0.8 0.8]);
            obj.HeadHandle = [h1 h2 h3 h4 h5 h6];
            axis([-650 650 -650 650]);
            axis square;
            axis off;
            box on;
            
            % add probability bars
            obj.Posteriors = zeros(1,obj.NumPosteriors);
            obj.Angles = 0:(360/obj.NumPosteriors):359;
            obj.HeadRotationDegrees = 0;
            [x,y] = deal(zeros(1,4));
            for ii=1:obj.NumPosteriors
                angle_rad1 = -2*pi*(ii-1.5)/obj.NumPosteriors;
                angle_rad2 = -2*pi*(ii-0.5)/obj.NumPosteriors;
                
                sn = sin(angle_rad1); cs = cos(angle_rad1);
                x(1) = obj.INNER_RADIUS*sn;
                y(1) = obj.INNER_RADIUS*cs;
                x(2) = (obj.INNER_RADIUS+obj.OUTER_RADIUS*obj.Posteriors(ii))*sn;
                y(2) = (obj.INNER_RADIUS+obj.OUTER_RADIUS*obj.Posteriors(ii))*cs;
                sn = sin(angle_rad2); cs = cos(angle_rad2);
                x(3) = (obj.INNER_RADIUS+obj.OUTER_RADIUS*obj.Posteriors(ii))*sn;
                y(3) = (obj.INNER_RADIUS+obj.OUTER_RADIUS*obj.Posteriors(ii))*cs;
                x(4) = obj.INNER_RADIUS*sn;
                y(4) = obj.INNER_RADIUS*cs;
                % obj.BarHandle(i) = plot([x1 x2],[y1 y2],'Color',[1.0 0.6471 0],'LineWidth',obj.LINE_WIDTH);
                obj.BarHandle(ii) = patch('XData',x,'YData',y,'LineStyle','none');
            end
            
            % add markers
            y2 = obj.MARKER_RADIUS;
            y1 = obj.INNER_RADIUS;
            col = [1 1 1];

            for ii = 1:4
                obj.MarkerHandle(ii) = fill(15*sin(-linspace(0,2*pi,30)),y2+15*cos(-linspace(0,2*pi,30)),col,'EdgeColor',col);
                obj.MarkerTextHandle(ii) = text(y1,y2, '', 'Color', col, 'FontSize', 12);
            end
            obj.TextHandle = text(y1,y2, '', 'Color', col, 'FontSize', 12);
            
            for ii=1:55
                obj.MarkerHandles(ii) = fill(15*sin(-linspace(0,2*pi,30)), ...
                    y2+15*cos(-linspace(0,2*pi,30)), ...
                    col,'linestyle','none');
                
                obj.TextHandles(ii) = text(y1,y2, '', 'Color', col, 'FontSize', 11);
            end
            
            for ii=1:13
                obj.idTextHandles(ii) = text(y1, y2, '', 'Color', col, 'FontSize', 11);
            end
            hold off;
            drawnow;
        end
        
        function obj = setScaleFactor(obj,val)
            if (nargin>0)
                obj.ScaleFactor = val;
                draw(obj);
            end
        end
        
        function colourVector = getIdentityColor(obj, label)
            if obj.ksColourMap.isKey(label)
                % If we've seen this sound type, try to use the same colour
                colourVector = obj.colourList(obj.ksColourMap(label),:);
            else
                % Get a new colour
                obj.ksColourMap(label) = obj.colourIndex;
                colourVector = obj.colourList(obj.colourIndex,:);
                obj.colourIndex = obj.colourIndex + 1;
                if obj.colourIndex > size(obj.colourList, 1)
                    obj.colourIndex = 1;
                end
            end
        end
                
        function radius = getIdentityRadius(obj, label)
            if obj.idRadiusMap.isKey(label)
                % If we've seen this sound type, use the same radius
                radius = obj.radiusList(obj.idRadiusMap(label));
            else
                % Get a new radius
                obj.idRadiusMap(label) = obj.radiusIndex;
                radius = obj.radiusList(obj.radiusIndex);
                obj.radiusIndex = obj.radiusIndex + 1;
                if obj.radiusIndex > numel(obj.radiusList)
                    obj.radiusIndex = 1;
                end
            end
        end
        
        function obj = plotMarkerAtAngle(obj,idx,angle,str,hue)
            if nargin < 5
                hue = 100;
            end
            sn = sin(-2*pi*angle/360);
            cs = cos(-2*pi*angle/360);
            x2 = (obj.MARKER_RADIUS-20) * sn;
            y2 = (obj.MARKER_RADIUS-20) * cs;
            col = obj.getIdentityColor(str);
            set(obj.MarkerHandle(idx), 'EdgeColor', col, ...
             'XData', x2+15*sin(-linspace(0,2*pi,30)), ...
             'YData', y2+15*cos(-linspace(0,2*pi,30)));
            r = (obj.MARKER_RADIUS+20);
            str = VisualiserIdentityLocalisation.getShortName(str);
            set(obj.MarkerTextHandle(idx), ...
                'Color', col, ...
                'Position', [r*sn, r*cs], ...
                'String', str, ...
                'rotation', angle);
        end
        
        function obj = plotMarkerIdxAtAngle(obj,...
                idx,...
                angle,...
                prob,...
                color,...
                radiusDelta)
            sn = sin(-2*pi*angle/360);
            cs = cos(-2*pi*angle/360);
            radius = obj.MARKER_RADIUS + radiusDelta;
            x2 = radius * sn;
            y2 = radius * cs;
            set(obj.MarkerHandles(idx), 'FaceColor', color, ...
                'XData', x2+15*sin(-linspace(0,2*pi,30)), ...
                'YData', y2+15*cos(-linspace(0,2*pi,30)));
        end
        
        function obj = plotTextIdxAtAngle(obj, ...
                idx, label, angle, radiusDelta, color)
            
            if angle > 90 && angle <= 270
                angle = angle + 4;
            else
                angle = angle - 4;
            end
            sn = sin(-2*pi*angle/360);
            cs = cos(-2*pi*angle/360);
            %radiusDelta = obj.getIdentityRadius(label);
            radius = obj.MARKER_RADIUS + radiusDelta;
            radiusInner = obj.INNER_RADIUS + radiusDelta;
            x2 = radius * sn;
            y2 = radius * cs;
            
            if angle > 90 && angle <= 270
                angle = angle + 180; % let text appear upright
            end
            
            set(obj.TextHandles(idx), ...
                'Color', color, ... % obj.getIdentityColor(label), ...
                'Position', [x2, y2], ...
                'String', label, ...
                'rotation', angle);
        end
        
        function obj = plotIdTextIdxAtAngle(obj, ...
                idx, label, prob)
            x2 = 480;
            y2 = 570 + obj.getIdentityRadius(label);
            set(obj.idTextHandles(idx), ...
                'Color', obj.getIdentityColor(label), ...
                'Position', [x2, y2], ...
                'String', [num2str(int16(prob*100)), '% ', label]);
        end
        
        function obj = setHeadRotation(obj,val)
            if (nargin>0)
                axes(obj.drawHandle);
                rotate(obj.HeadHandle,[0 0 1],val-obj.HeadRotationDegrees);
                obj.HeadRotationDegrees = val;
            else
                error('parameter required');
            end
        end
        
        function obj = setHue(obj,val)
            if nargin>0
                if (val>=0 && val<=360)
                    obj.Hue = val;
                    draw(obj);
                else
                    error('invalid hue');
                end
            end
        end
        
        function draw(obj)
            
            axes(obj.drawHandle);
            
            p = obj.Posteriors*obj.ScaleFactor;
            % clip, otherwise color calculation could crash
            p(p>1.0)=1.0;
            p(p<0.0)=0.0;
            numPosteriors = length(obj.Posteriors);
            angDiff = 360/numPosteriors/2;
            for i=1:numPosteriors
                angle_rad1 = -2*pi*(obj.Angles(i)-angDiff)/360;
                angle_rad2 = -2*pi*(obj.Angles(i)+angDiff)/360;
                
                sn = sin(angle_rad1); cs = cos(angle_rad1);
                x(1) = obj.INNER_RADIUS*sn;
                y(1) = obj.INNER_RADIUS*cs;
                x(2) = (obj.INNER_RADIUS+obj.OUTER_RADIUS*p(i))*sn;
                y(2) = (obj.INNER_RADIUS+obj.OUTER_RADIUS*p(i))*cs;
                sn = sin(angle_rad2); cs = cos(angle_rad2);
                x(3) = (obj.INNER_RADIUS+obj.OUTER_RADIUS*p(i))*sn;
                y(3) = (obj.INNER_RADIUS+obj.OUTER_RADIUS*p(i))*cs;
                x(4) = obj.INNER_RADIUS*sn;
                y(4) = obj.INNER_RADIUS*cs;
                set(obj.BarHandle(i),'xdata',x,'ydata',y);
                set(obj.BarHandle(i),'FaceColor',hsv2rgb([obj.Hue/360 0.96 (1.0-0.3*p(i))]));
            end
        end
        
        function obj = setPosteriors(obj,angles,posteriors)
            if length(angles)==length(posteriors)
                obj.Posteriors = posteriors;
                obj.Angles = angles;
            else
                error('number of angles must be the same as number of posteriors');
            end
            draw(obj);
        end
        
        function obj = setLocationIdentity(obj, ...
                labels, probs, ds, locs)
            
            y2 = obj.MARKER_RADIUS;
            y1 = obj.INNER_RADIUS;
            color = [0.9 0.9 0.9];
            
            % first clear handles
            for ii=1:numel(obj.MarkerHandles)
                set(obj.MarkerHandles(ii), 'FaceColor', color, ...
                    'XData', 15*sin(-linspace(0,2*pi,30)), ...
                    'YData', 15*cos(-linspace(0,2*pi,30)));
                set(obj.TextHandles(ii), ...
                    'Color', color, ...
                    'Position', [y1, y2], ...
                    'String', '');
            end
            
            % populate with new info
            for idx = 1:numel(labels)
                if ds{idx} == 1
                    label = VisualiserIdentityLocalisation.getShortName(labels{idx});
                    radius = obj.getIdentityRadius(label);
                    color = obj.getIdentityColor(label);
                    theta = locs{idx}+obj.HeadRotationDegrees;
                    
                    obj.plotTextIdxAtAngle(idx, ...
                        sprintf('%.0f%% %s', probs{idx}*100, label), ...
                        theta, radius, color);
                    
                    obj.plotMarkerIdxAtAngle(idx, ...
                        theta, ...
                        probs{idx}, ...
                        color,...
                        radius);
                end
            end
        end
        
        function obj = setIdentity(obj, ...
                labels, probs, ds)
            
            y2 = obj.MARKER_RADIUS;
            y1 = obj.INNER_RADIUS;
            color = [0.9 0.9 0.9];
            
            for ii=1:numel(obj.idTextHandles)
                set(obj.idTextHandles(ii), ...
                    'Color', color, ...
                    'Position', [y1, y2], ...
                    'String', '');
            end
            
            for idx = 1:numel(labels)
%                 if ds{idx} == 1
                    obj.plotIdTextIdxAtAngle(idx, ...
                        VisualiserIdentityLocalisation.getShortName(labels{idx}), ...
                        probs{idx});
%                 end
            end
        end
        
        function obj = setNumberOfSourcesText(obj, ...
                numSrcs)
            angle = 45;
            radius = obj.MARKER_RADIUS+220;
            sn = sin(-2*pi*angle/360);
            cs = cos(-2*pi*angle/360);
            x2 = radius * sn;
            y2 = radius * cs;
            if ischar(numSrcs)
                str = ''; %sprintf('Attended to "%s" source', numSrcs);
            elseif numSrcs > 1
                str = sprintf('%d sources', numSrcs);
            else
                str = sprintf('%d source', numSrcs);
            end
            set(obj.TextHandle, ...
                'Color', [0.0000    0.4470    0.7410], ...
                'Position', [x2, y2], ...
                'FontSize', 17, ...
                'String', str);
        end
    end
    
    methods (Static)
        function newName = getShortName(label)
            if strcmp(label, 'maleSpeech')
                newName = 'male';
            elseif strcmp(label, 'femaleSpeech')
                newName = 'female';
            elseif strcmp(label, 'femaleScreammaleScream')
                newName = 'scream';
            else
                newName = label;
            end
        end
    end
end
