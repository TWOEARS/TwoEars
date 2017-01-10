function signalIndex = nameToSignal ( name, allPorts )

    signalIndex = -1;
    
    for ii = 1:length(allPorts)
        if ( strcmp(allPorts{ii}.name, name))
            signalIndex = ii;
        end
    end
end