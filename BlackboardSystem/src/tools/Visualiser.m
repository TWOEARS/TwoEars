% Simple class to visualise sound localisation
% Assumed that vector of posterior probabilties is given, scaled in range
% [0,1]
% Head rotation can also be updated
% Example:
% v = Visualiser(72);                   % initialise for 72 angles
% v = v.setPosteriors(rand(1,72));      % set prob of each angle to random
% v = v.setHeadRotation(45);            % rotate head to 45 degrees (RHR)
% v = v.setHue(30);                     % set the hue to 30 degres
% v = v.setScaleFactor(1.5);            % set scale factor to 1.5
% GJB 13/5/2016

classdef Visualiser
    
    properties(Constant)
        INNER_RADIUS = 175;
        OUTER_RADIUS = 300;
        LINE_WIDTH = 4.0;
    end
    
    properties (SetAccess = private)
        Posteriors
        HeadRotationDegrees = 0
        NumPosteriors
        FigureNum
        HeadHandle
        BarHandle
        Hue = 50 % hue in HSV space, default is orangey yellow
        ScaleFactor = 1.0
    end
    
    methods
        
        function obj = Visualiser(val)
            if nargin>0
                if isnumeric(val)
                    obj.NumPosteriors = val;
                else
                    error('number of posteriors required');
                end
            else
                error('number of posteriors required');
            end
            obj.BarHandle = zeros(1,obj.NumPosteriors);
            obj.FigureNum = figure;
            x=sin(linspace(0,2*pi,50));
            y=cos(linspace(0,2*pi,50));
            hold on;
            c=[0.9 0.9 0.9];
            h1 = fill(-90+20*x,40*y,c);
            h2 = fill(90+20*x,40*y,c);
            h3 = fill([-30 30 0 -30],[90 90 130 90],c);
            h4 = fill(90*x,100*y,c);
            obj.HeadHandle = [h1 h2 h3 h4];
            axis([-500 500 -500 500]);
            axis square;
            box on;
            obj.Posteriors = zeros(1,obj.NumPosteriors);
            for i=1:obj.NumPosteriors
                x1 = obj.INNER_RADIUS*sin(2*pi*(i-1)/obj.NumPosteriors);
                y1 = obj.INNER_RADIUS*cos(2*pi*(i-1)/obj.NumPosteriors);
                x2 = (obj.INNER_RADIUS+obj.OUTER_RADIUS*obj.Posteriors(i))*sin(2*pi*(i-1)/obj.NumPosteriors);
                y2 = (obj.INNER_RADIUS+obj.OUTER_RADIUS*obj.Posteriors(i))*cos(2*pi*(i-1)/obj.NumPosteriors);
                obj.BarHandle(i)=plot([x1 x2],[y1 y2],'Color',[1.0 0.6471 0],'LineWidth',obj.LINE_WIDTH);
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
        
        function obj = setHeadRotation(obj,val)
            if (nargin>0)
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
            p = obj.Posteriors*obj.ScaleFactor;
            % clip, otherwise color calculation could crash
            p(p>1.0)=1.0;
            for i=1:obj.NumPosteriors
                x1 = obj.INNER_RADIUS*sin(2*pi*(i-1)/obj.NumPosteriors);
                y1 = obj.INNER_RADIUS*cos(2*pi*(i-1)/obj.NumPosteriors);
                x2 = (obj.INNER_RADIUS+obj.OUTER_RADIUS*p(i))*sin(2*pi*(i-1)/obj.NumPosteriors);
                y2 = (obj.INNER_RADIUS+obj.OUTER_RADIUS*p(i))*cos(2*pi*(i-1)/obj.NumPosteriors);
                set(obj.BarHandle(i),'xdata',[x1 x2],'ydata',[y1 y2]);
                set(obj.BarHandle(i),'Color',hsv2rgb([obj.Hue/360 0.96 (1.0-0.3*p(i))]));
            end
        end
        
        function obj = setPosteriors(obj,val)
            if nargin>0
                if (length(val)==obj.NumPosteriors)
                    obj.Posteriors = val;
                else
                    error('number of posteriors is incorrect');
                end
                draw(obj);
            else
                error('parameter required');
            end
        end
        
    end
end
