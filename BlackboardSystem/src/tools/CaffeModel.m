classdef CaffeModel < handle
    % PREREQUISITE:
    % 1. caffe library path (directory containing libcaffe.so must be added to
    % the LD_LIBRARY_PATH environment variable PRIOR to launching MATLAB)
    % 2. the path to caffe's matlab interface needs to be added to the
    % matlab search path Example addpath(/home/myuser/src/caffe/matlab/+caffe')
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        fpath_net_def;
        fpath_weights;
        thr;            % output node thresholds, default is 0.5
        has_thr;
    end
    
    properties (SetAccess = protected, Transient=true)
        net;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = CaffeModel(modelDir, ...
                fname_net_def, fname_weights, ...
                thr)
            obj.net = [];
            obj.initNet(modelDir, fname_net_def, fname_weights);
            if exist('thr', 'var') && ~isempty(thr)
                obj.thr = thr;
                if ~isa(obj.thr, 'cell')
                    obj.thr = {obj.thr};
                end
                obj.has_thr = true;
            else
                obj.has_thr = false;
            end
        end
        %% -----------------------------------------------------------------
        

        %% -----------------------------------------------------------------
        function initNet(obj, modelDir, fname_net_def, fname_weights)
            % INITNET
            % innitialize underlying caffe network object from definition
            % and weight files
            %% --------------------------------------------------------------------
            obj.fpath_net_def = db.getFile(fullfile(modelDir, fname_net_def));
            obj.fpath_weights = db.getFile(fullfile(modelDir, fname_weights));
            
            phase = 'test'; % run with phase test (so that dropout isn't applied)
            if ~isempty(obj.net)
                delete(obj.net);
                clear obj.net;
            end
            obj.net = caffe.Net(obj.fpath_net_def, obj.fpath_weights, phase);
        end
        %% -----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods(Access = public)
        
        function [y,score] = applyModel( obj, x )
            blobs_in = x{1};
            blobs_in_names = x{2};
            data_in = cell(1, numel(obj.net.inputs));
            % prepare input data by selecting required features
            net_needs_reshape = false;
            for ii = 1:numel(obj.net.inputs)
                for jj = 1:numel(blobs_in_names)
                    if strcmp(blobs_in_names{jj}, obj.net.inputs{ii})
                        data_in{ii} = blobs_in{jj};
                        sz_data = size(data_in{ii});
                        batch_sz_data = sz_data(numel(sz_data));
                        
                        expected_sz_data = obj.net.blobs(obj.net.inputs{ii}).shape;
                        expected_batch_sz_data = expected_sz_data;
                        % reshape input blob if necessary
                        if batch_sz_data ~= expected_batch_sz_data
                            batch_sz_data_new = expected_batch_sz_data;
                            batch_sz_data_new(numel(expected_sz_data)) = batch_sz_data;
                            obj.net.blobs(obj.net.inputs{ii}).reshape(batch_sz_data_new)
                            net_needs_reshape = true;
                        end
                    end
                end
            end
            if net_needs_reshape
                obj.net.reshape();
            end
            blobs_out = obj.net.forward(data_in);
            % extract predictions from network
            score = {};
            y = {};
            for ii = 1:numel(obj.net.outputs)
                score.(obj.net.outputs{ii}) = double(blobs_out{ii});
                d = blobs_out{ii};
                if obj.has_thr
                    thr_tmp = obj.thr{ii};
                else
                    thr_tmp = 0.5;
                end
                d = squeeze(d);
                mask_neg = d < thr_tmp;
                d(d >= thr_tmp) = 1;
                d(mask_neg) = -1;
                y.(obj.net.outputs{ii}) = d;
            end
        end
        %% -----------------------------------------------------------------

        function delete(obj)
            % DELETE Destructor
            
            % Shut down the network
            delete(obj.net);
            clear obj.net;
        end
        
    end
    
    methods (Static)

        function setMode(use_gpu, gpu_id)
            % Set caffe mode (gpu or cpu mode)
            if exist('use_gpu', 'var') && use_gpu
                caffe.set_mode_gpu();
                if ~exist('gpu_id', 'var')
                    gpu_id = 0;  % we will use the first gpu in this demo
                end
                caffe.set_device(gpu_id);
                fprintf( 'Using caffe in GPU mode, device id:%d.\n', gpu_id );
            else
                caffe.set_mode_cpu();
                fprintf( 'Using caffe in CPU mode.\n' );
            end
        end
        %% -----------------------------------------------------------------

    end
    
end

