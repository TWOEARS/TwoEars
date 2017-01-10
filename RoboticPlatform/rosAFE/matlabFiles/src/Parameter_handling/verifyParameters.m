function [result, hproc] = verifyParameters( mObj, type, p, name)

            result = 0;
            hproc = 0;
            
            if nargin < 4
                name = [];
            end

            switch ( type )
                
                case ('input')

                    % Loop over the preProc processors
                    for ii = 1:length(mObj.Processors.input)

                        % Get a handle to that processor, for readability in the
                        % following
                        proc = mObj.Processors.input{ii};
                            
                        if ( (length(name)==0) || ( strcmp(name, proc.name) ) )
                            hproc = proc;
                            result = 1;
                        end
                    end                 
                
                
                case ('preProc')
                   
                   defaultParams = Parameters.getProcessorDefault(type);
                   % Loop over the preProc processors
                    for ii = 1:length(mObj.Processors.preProc)

                        % Get a handle to that processor, for readability in the
                        % following
                        proc = mObj.Processors.preProc{ii};
                            
                        if ( (length(name)==0) || ( strcmp(name, proc.name) ) )
                             if ( (proc.pp_bRemoveDC == defaultOrAsked(p , defaultParams, 'pp_bRemoveDC')) && ...  
                                  (proc.pp_cutoffHzDC == defaultOrAsked(p , defaultParams, 'pp_cutoffHzDC')) && ...
                                  (proc.pp_bPreEmphasis == defaultOrAsked(p , defaultParams, 'pp_bPreEmphasis')) && ...  
                                  (proc.pp_coefPreEmphasis == defaultOrAsked(p , defaultParams, 'pp_coefPreEmphasis')) && ...  
                                  (proc.pp_bNormalizeRMS == defaultOrAsked(p , defaultParams, 'pp_bNormalizeRMS')) && ...
                                  (proc.pp_intTimeSecRMS == defaultOrAsked(p , defaultParams, 'pp_intTimeSecRMS')) && ...  
                                  (proc.pp_bLevelScaling == defaultOrAsked(p , defaultParams, 'pp_bLevelScaling')) && ...  
                                  (proc.pp_refSPLdB == defaultOrAsked(p , defaultParams, 'pp_refSPLdB')) && ...  
                                  (proc.pp_bMiddleEarFiltering == defaultOrAsked(p , defaultParams, 'pp_bMiddleEarFiltering')) && ...  
                                   strcmp(proc.pp_middleEarModel, defaultOrAsked(p , defaultParams, 'pp_middleEarModel')) && ...
                                  (proc.pp_bUnityComp == defaultOrAsked(p , defaultParams, 'pp_bUnityComp')) )
                              
                                   dep = mObj.RosAFE.getDependencies(proc.name);
                                   result = verifyParameters( mObj, 'input', p, dep.result.dependencies(end -1 ) );   
                                   
                                   if ( result == 1 )
                                       hproc = proc;
                                   end

                            end
                        end
                    end  
                   
                case ('gammatoneProc')
                    
                   defaultParams = Parameters.getProcessorDefault(type);
                   % Loop over the gammatone processors
                    for ii = 1:length(mObj.Processors.gammatone)

                        % Get a handle to that processor, for readability in the
                        % following
                        proc = mObj.Processors.gammatone{ii};
                            
                        if ( (length(name)==0) || ( strcmp(name, proc.name) ) )
                             if ( strcmp(proc.fb_type, defaultOrAsked(p , defaultParams, 'fb_type')) && ...
                                  (proc.fb_lowFreqHz == defaultOrAsked(p , defaultParams, 'fb_lowFreqHz')) && ...  
                                  (proc.fb_highFreqHz == defaultOrAsked(p , defaultParams, 'fb_highFreqHz')) && ...
                                  (proc.fb_nERBs == defaultOrAsked(p , defaultParams, 'fb_nERBs')) && ...  
                                  (proc.fb_nGamma == defaultOrAsked(p , defaultParams, 'fb_nGamma')) && ...  
                                  (proc.fb_bwERBs == defaultOrAsked(p , defaultParams, 'fb_bwERBs')) )
                              
                                 % (proc.fb_nChannels == defaultOrAsked(p , defaultParams, 'fb_nChannels'))
                                 % (proc.fb_cfHz == defaultOrAsked(p , defaultParams, 'fb_cfHz')) && ...
                                 
                                % Then it is a suitable candidate, we should
                                % investigate its dependencies
                                dep = mObj.RosAFE.getDependencies(proc.name);
                                result = verifyParameters( mObj, 'preProc', p, dep.result.dependencies(end -1 ));
                                if ( result == 1 )
                                    hproc = proc;
                                end
                            end
                        end
                    end                    
                case ('ihcProc')

                    defaultParams = Parameters.getProcessorDefault(type);
                    % Loop over the IHC processors
                    for ii = 1:length(mObj.Processors.ihc)

                        % Get a handle to that processor, for readability in the
                        % following
                        proc = mObj.Processors.ihc{ii};
                            
                        if ( (length(name)==0) || ( strcmp(name, proc.name) ) )
                            if ( strcmp(proc.ihc_method, defaultOrAsked(p , defaultParams, 'ihc_method')) )

                                % Then it is a suitable candidate, we should
                                % investigate its dependencies
                                dep = mObj.RosAFE.getDependencies(proc.name);
                                result = verifyParameters( mObj, 'gammatoneProc', p, dep.result.dependencies(end -1 ));
                                if ( result == 1 )
                                    hproc = proc;
                                end
                            end
                        end
                    end
                    
                case ('ildProc')

                    defaultParams = Parameters.getProcessorDefault(type);
                    % Loop over the ILD processors
                    for ii = 1:length(mObj.Processors.ild)

                        % Get a handle to that processor, for readability in the
                        % following
                        proc = mObj.Processors.ild{ii};
                            
                        if ( (length(name)==0) || ( strcmp(name, proc.name) ) )
                            if ( strcmp(proc.ild_wname, defaultOrAsked(p , defaultParams, 'ild_wname')) && ...
                                 (proc.ild_wSizeSec == defaultOrAsked(p , defaultParams, 'ild_wSizeSec')) && ...  
                                 (proc.ild_hSizeSec == defaultOrAsked(p , defaultParams, 'ild_hSizeSec')) )

                                % Then it is a suitable candidate, we should
                                % investigate its dependencies
                                dep = mObj.RosAFE.getDependencies(proc.name);
                                result = verifyParameters( mObj, 'ihcProc', p, dep.result.dependencies(end -1 ));
                                if ( result == 1 )
                                    hproc = proc;
                                end
                                    
                            end
                        end
                    end

              case ('ratemapProc')

                    defaultParams = Parameters.getProcessorDefault(type);
                    % Loop over the ILD processors
                    for ii = 1:length(mObj.Processors.ratemap)

                        % Get a handle to that processor, for readability in the
                        % following
                        proc = mObj.Processors.ratemap{ii};
                            
                        if ( (length(name)==0) || ( strcmp(name, proc.name) ) )
                            if ( strcmp(proc.rm_wname, defaultOrAsked(p , defaultParams, 'rm_wname')) && ...
                                 (proc.rm_hSizeSec == defaultOrAsked(p , defaultParams, 'rm_hSizeSec')) && ...  
                                 (proc.rm_decaySec == defaultOrAsked(p , defaultParams, 'rm_decaySec')) && ...
                                 (proc.rm_wSizeSec == defaultOrAsked(p , defaultParams, 'rm_wSizeSec')) && ...  
                                 strcmp(proc.rm_scaling, defaultOrAsked(p , defaultParams, 'rm_scaling')) )
                                % Then it is a suitable candidate, we should
                                % investigate its dependencies
                                dep = mObj.RosAFE.getDependencies(proc.name);
                                result = verifyParameters( mObj, 'ihcProc', p, dep.result.dependencies(end -1 ));
                                if ( result == 1 )
                                    hproc = proc;
                                end
                                    
                            end
                    end      
                    end
                
             case ('crosscorrelationProc')

                    defaultParams = Parameters.getProcessorDefault(type);
                    % Loop over the ILD processors
                    for ii = 1:length(mObj.Processors.crossCorrelation)

                        % Get a handle to that processor, for readability in the
                        % following
                        proc = mObj.Processors.crossCorrelation{ii};
                            
                        if ( (length(name)==0) || ( strcmp(name, proc.name) ) )
                            if ( strcmp(proc.cc_wname, defaultOrAsked(p , defaultParams, 'cc_wname')) && ...
                                 (proc.cc_hSizeSec == defaultOrAsked(p , defaultParams, 'cc_hSizeSec')) && ...  
                                 (proc.cc_wSizeSec == defaultOrAsked(p , defaultParams, 'cc_wSizeSec')) && ...  
                                 (proc.cc_maxDelaySec == defaultOrAsked(p , defaultParams, 'cc_maxDelaySec')) )
                             
                                % Then it is a suitable candidate, we should
                                % investigate its dependencies
                                dep = mObj.RosAFE.getDependencies(proc.name);
                                result = verifyParameters( mObj, 'ihcProc', p, dep.result.dependencies(end -1 ));
                                if ( result == 1 )
                                    hproc = proc;
                                end
                                    
                            end
                    end      
                    end                 
                    
                otherwise
                    result = 0;
            end




end