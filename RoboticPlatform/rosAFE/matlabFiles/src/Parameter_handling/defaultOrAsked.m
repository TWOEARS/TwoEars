function value = defaultOrAsked( parameterMapArg, defaultParametersMapArg, askedParameterName )

    try
        value = parameterMapArg.map(askedParameterName);
    catch ME
        if (strcmp(ME.identifier,'MATLAB:Containers:Map:NoKey'))
            value = defaultParametersMapArg.map(askedParameterName);
        end
        if (strcmp(ME.identifier,'MATLAB:nonStrucReference'))
            value = defaultParametersMapArg.map(askedParameterName);
        end     
    end
    
    if isempty(value)
        value = 0;
    end
    
end
