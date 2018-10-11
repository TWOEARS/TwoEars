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

classdef VisualiserLocalisation < handle
    
    properties(Constant)
        INNER_RADIUS = 175;
        OUTER_RADIUS = 300;
        MARKER_RADIUS = 620;
        LINE_WIDTH = 8.0;
        SHOW_GRID = true;
        NUM_GRID_LINES = 36;
    end
    
    properties (SetAccess = private)
        Angles
        Posteriors
        HeadRotationDegrees = 0
        NumPosteriors = 72
        drawHandle
        HeadHandle
        MarkerHandle
        BarHandle
        Hue = 50 % hue in HSV space, default is orangey yellow
        ScaleFactor = 2.5
    end
    
    methods
        
        function obj = VisualiserLocalisation(drawHandle)
            if nargin>0
                obj.drawHandle = drawHandle;
            else
                figure('Color',[1 1 1]);
                obj.drawHandle = gca;
            end
            obj.BarHandle = zeros(1,obj.NumPosteriors);
            obj.reset();
        end
        
        function reset(obj)
            axes(obj.drawHandle);
            cla;
            x=sin(linspace(0,2*pi,50));
            y=cos(linspace(0,2*pi,50));
            c=[0.9 0.9 0.9];
            hold on;
            
            % add a grid if required
            if (obj.SHOW_GRID)
                for i=1:obj.NUM_GRID_LINES
                    angle_degrees = wrapTo180((i-1)*360/obj.NUM_GRID_LINES);
                    angle_rad = -2*pi*angle_degrees/360;
                    sn = sin(angle_rad); cs = cos(angle_rad);
                    plot([obj.INNER_RADIUS*sn 520*sn],[obj.INNER_RADIUS*cs 520*cs],'Color',c);
                    text(560*sn,560*cs,num2str(angle_degrees),'HorizontalAlignment','Center','Color',[0.7 0.7 0.7]);
                end
                % circles
                for i=0:4
                    r=obj.INNER_RADIUS+i*(500-obj.INNER_RADIUS)/4;
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
            
            % add markers
            y2 = obj.MARKER_RADIUS;
            y1 = obj.INNER_RADIUS;
            col = [1 1 1];
            obj.MarkerHandle(1) = plot([y1 y2], [y1 y2], 'Color', col, 'LineStyle', '--');
            obj.MarkerHandle(2) = fill(15*sin(-linspace(0,2*pi,30)),y2+15*cos(-linspace(0,2*pi,30)),col,'linestyle','none');
            
            % add probability bars
            obj.Posteriors = zeros(1,obj.NumPosteriors);
            obj.Angles = 0:(360/obj.NumPosteriors):359;
            obj.HeadRotationDegrees = 0;
            [x,y] = deal(zeros(1,4));
            for i=1:obj.NumPosteriors
                angle_rad1 = -2*pi*(i-1.5)/obj.NumPosteriors;
                angle_rad2 = -2*pi*(i-0.5)/obj.NumPosteriors;
                
                sn = sin(angle_rad1); cs = cos(angle_rad1);
                x(1) = obj.INNER_RADIUS*sn;
                y(1) = obj.INNER_RADIUS*cs;
                x(2) = (obj.INNER_RADIUS+obj.OUTER_RADIUS*obj.Posteriors(i))*sn;
                y(2) = (obj.INNER_RADIUS+obj.OUTER_RADIUS*obj.Posteriors(i))*cs;
                sn = sin(angle_rad2); cs = cos(angle_rad2);
                x(3) = (obj.INNER_RADIUS+obj.OUTER_RADIUS*obj.Posteriors(i))*sn;
                y(3) = (obj.INNER_RADIUS+obj.OUTER_RADIUS*obj.Posteriors(i))*cs;
                x(4) = obj.INNER_RADIUS*sn;
                y(4) = obj.INNER_RADIUS*cs;
                % obj.BarHandle(i) = plot([x1 x2],[y1 y2],'Color',[1.0 0.6471 0],'LineWidth',obj.LINE_WIDTH);
                obj.BarHandle(i) = patch('XData',x,'YData',y,'LineStyle','none');
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
        
        function obj = plotMarkerAtAngle(obj,angle,str,hue)
            if nargin < 4
                hue = 100;
            end
            sn = sin(-2*pi*angle/360);
            cs = cos(-2*pi*angle/360);
            x2 = obj.MARKER_RADIUS * sn;
            y2 = obj.MARKER_RADIUS * cs;
            x1 = obj.INNER_RADIUS * sn;
            y1 = obj.INNER_RADIUS * cs;
            col = hsv2rgb(hue/360,0.9,0.6);
            set(obj.MarkerHandle(1), 'Color', col, 'XData', [x1 x2], 'YData', [y1 y2]);
            set(obj.MarkerHandle(2), 'FaceColor', col, ...
                'XData', x2+15*sin(-linspace(0,2*pi,30)), ...
                'YData', y2+15*cos(-linspace(0,2*pi,30)));
            text(x,y,str,'HorizontalAlignment','Center','VerticalAlignment','Middle','fontsize',18,'Color',[1 1 1]);
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
                hsv = [obj.Hue/360 0.96 (1.0-0.3*p(i))];
                hsv(hsv>1) = 1;
                set(obj.BarHandle(i),'FaceColor',hsv2rgb(hsv));
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
        
    end
end
