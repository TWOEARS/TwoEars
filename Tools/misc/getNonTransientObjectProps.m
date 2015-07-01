function objProps = getNonTransientObjectProps( obj )

mcdata = metaclass( obj );
propsData = mcdata.PropertyList;
warning off MATLAB:structOnObject
propsStruct = struct( obj );
warning on MATLAB:structOnObject
pNames = sort( {propsData.Name} );
objProps = {};
for pname = pNames
    p = propsData(strcmp( {propsData.Name}, pname{1} ));
    if p.Transient, continue; end
    if ~isfield( propsStruct, p.Name ), continue; end
    objProps{end+1} = propsStruct.(p.Name);
end

end
