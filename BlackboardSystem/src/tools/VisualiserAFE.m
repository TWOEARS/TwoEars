% Simple class to visualise AFE features
% NM 21/09/2016

classdef VisualiserAFE < handle
    
    properties (SetAccess = private)
        drawHandle;         % draw handles
        updateTime = 0.5;   % update every updateTime seconds
        bufferLength = 1.5;
        
        %hLeftEar;
        %hRightEar;
        hRatemap;
        hMask;
        hItd;
        hIld;
        sigmax = 1E-9;
        
        maskBuffer
        nMaskFrames = 0;
    end
    
    methods
        
        function obj = VisualiserAFE(drawHandle)
            obj.drawHandle = drawHandle;
            obj.maskBuffer = zeros(32, obj.bufferLength * 100);
        end
        
        function reset(obj)

            obj.sigmax = 1E-9;
            
%             % Left ear signal
%             subplot(2,2,3,'Parent',obj.drawHandle);
%             obj.hLeftEar = plot(0, 'Color', [0 .447 .741]);
%             axis tight; ylim([-1 1]);
%             %xlabel('Time (s)', 'FontSize', 14);
%             set(gca,'XTick', [], 'XTickLabel',{});
%             title('Left ear signal', 'FontSize', 14);
%                 
%             % Right ear signal
%             subplot(2,2,4,'Parent',obj.drawHandle);
%             obj.hRightEar = plot(0, 'Color', [0 .447 .741]);
%             axis tight; ylim([-1 1]);
%             %xlabel('Time (s)', 'FontSize', 14);
%             set(gca,'XTick', [], 'XTickLabel',{});
%             title('Right ear signal', 'FontSize', 14);
            % Ratemap
            subplot(2,2,1,'Parent',obj.drawHandle);
            obj.hRatemap = image([], 'CDataMapping', 'scaled');
            axis xy
            set(gca, 'YDir','normal', ...
                     'xlimmode','manual',...
                     'ylimmode','manual',...
                     'zlimmode','manual',...
                     'climmode','manual',...
                     'alimmode','manual',...
                     'CLimMode', 'auto');
            axis tight; ylim([1 32]);
            ylabel('Centre Freq. (Hz)', 'FontSize', 14);
            set(gca,'XTick', [], 'XTickLabel',{}, ...
               'YTick', [1 8 16 24 32], 'YTickLabel', {'80','420','1300', '3300', '8000'});
            title('Ratemap', 'FontSize', 14);
            
            % Mask
            subplot(2,2,2,'Parent',obj.drawHandle);
            obj.hMask = image([]); %, 'CDataMapping', 'scaled');
            axis xy
            set(gca, 'YDir','normal', ...
                     'xlimmode','manual',...
                     'ylimmode','manual',...
                     'zlimmode','manual',...
                     'climmode','manual',...
                     'alimmode','manual');
            axis tight; ylim([1 32]);
            ylabel('Centre Freq. (Hz)', 'FontSize', 14);
            set(gca,'XTick', [], 'XTickLabel',{}, ...
               'YTick', [1 8 16 24 32], 'YTickLabel', {'80','420','1300', '3300', '8000'});
            title('Top-down segregation mask', 'FontSize', 14);

            % Plot ITD
            subplot(2,2,3,'Parent',obj.drawHandle);
            obj.hItd = image([], 'CDataMapping', 'scaled');
            set(gca, 'YDir','normal', ...
                     'xlimmode','manual',...
                     'ylimmode','manual',...
                     'zlimmode','manual',...
                     'climmode','manual',...
                     'alimmode','manual',...
                     'CLimMode', 'auto');
            axis tight; ylim([-1 1]);
            ylabel('Lag (ms)', 'FontSize', 14);
            set(gca,'XTick', [], 'XTickLabel',{});
            title('Interaural time difference', 'FontSize', 14);
            
            % Plot ILD
            subplot(2,2,4,'Parent',obj.drawHandle);
            obj.hIld = plot(10,'.');
            axis tight; ylim([-10 10]);
            ylabel('ILD (dB)', 'FontSize', 14);
            set(gca,'XTick', [], 'XTickLabel',{});
            set(gca,'YTick',-10:5:10, 'YTickLabel',{'-10','-5','0','5','10'});
            title('Interaural level difference', 'FontSize', 14);

            colormap default;
            map = colormap;
            map(1,:) = [1 1 1];
            map(2,:) = [0 0 0];
            colormap(map);
        end
        
        function drawMask(obj, mask)
            
            nFrames = size(mask, 2);
            obj.nMaskFrames = obj.nMaskFrames + nFrames;
            if obj.nMaskFrames > size(obj.maskBuffer, 2)
                obj.nMaskFrames = size(obj.maskBuffer, 2);
            end
            
            obj.maskBuffer = circshift(obj.maskBuffer, -nFrames, 2);
            obj.maskBuffer(:, end-nFrames+1:end) = mask;

            mask = (obj.maskBuffer(:,end-obj.nMaskFrames+1:end) > 0.4) .* 2;
            set(obj.hMask, 'cdata', mask);
            
            %drawnow;
            
        end
        
        function draw(obj, data, timeStamp)
            
            sigLen = obj.bufferLength;
            
            % Plot ear signals
%             if isprop(data, 'time')
%                 sig = [data.time{1}.Data(:) data.time{2}.Data(:)];
%                 fsHz = data.time{1}.FsHz;
%                 nSamples = floor(sigLen * fsHz);
%                 if size(sig,1) < nSamples
%                     sigLen = obj.updateTime;
%                     nSamples = sigLen * fsHz;
%                 end
%                 
%                 x = (1:nSamples) ./ fsHz + (timeStamp-sigLen);
%                 sig = sig(end-nSamples+1:end,:);
%                 m = max(abs(sig(:)));
%                 if m > obj.sigmax
%                     obj.sigmax = m;
%                 end
%                 sig = sig ./ obj.sigmax;
%                 
%                 % Left ear
%                 set(obj.hLeftEar, 'xdata', x, 'ydata', sig(:,1));
% 
%                 % Right ear signal
%                 set(obj.hRightEar, 'xdata', x, 'ydata', sig(:,2));
%             end
            
            % Plot ITD
            if isprop(data, 'crosscorrelation')
                scorr = squeeze(mean(data.crosscorrelation{1}.Data(:),2));
                fsHz = data.crosscorrelation{1}.FsHz;
                nSamples = floor(sigLen * fsHz);
                if nSamples > size(scorr,1)
                    nSamples = size(scorr,1);
                end
                x = (1:nSamples) ./ fsHz + (timeStamp-sigLen);
                y = 1000.*data.crosscorrelation{1}.lags;
                scorr = scorr(end-nSamples+1:end, :)';
                scorr(1,1) = min(scorr(:))*0.9;
                set(obj.hItd, 'xdata', [x(1) x(end)], 'ydata', [y(1) y(end)], 'cdata', scorr);
            end
            
            % Plot ILD
            if isprop(data, 'ild')
                ild = mean(data.ild{1}.Data(:), 2);
                fsHz = data.ild{1}.FsHz;
                nSamples = floor(sigLen * fsHz);
                if nSamples > length(ild)
                    nSamples = length(ild);
                end
                ild = ild(end-nSamples+1:end);
                x = (1:nSamples) ./ fsHz + (timeStamp-sigLen);
                set(obj.hIld, 'xdata', x, 'ydata', ild);
            end
            
            % Plot Ratemap
            if isprop(data, 'ratemap')
                ratemap = (data.ratemap{1,1}.Data(:) + data.ratemap{1,2}.Data(:)) ./ 2;
                % log compression
                ratemap = log(max(ratemap, eps))';
            
                fsHz = data.ratemap{1}.FsHz;
                nSamples = floor(sigLen * fsHz);
                if nSamples > size(ratemap,2)
                    nSamples = size(ratemap,2);
                end
%                 obj.ratemapXData = (1:nSamples) ./ fsHz + (timeStamp-sigLen);
%                 obj.ratemapYData = data.ratemap{1}.cfHz;
                ratemap = ratemap(:,end-nSamples+1:end);
                ratemap(1,1) = min(ratemap(:))*1.01;
                set(obj.hRatemap, 'cdata', ratemap);
            end
            
            %drawnow;
        end
        
    end
end
