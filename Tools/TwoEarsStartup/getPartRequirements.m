function [paths, subs, subsRecursive, branches, startup] = getPartRequirements( configFileName )

config = xmlread( configFileName );

requirements = config.getElementsByTagName( 'TwoEarsPart' );

paths = {};
branches = {};
startup = {};
subs = {};
subsRecursive = {};
for k = 1:requirements.getLength()
    paths{end+1,1} = char( requirements.item(k-1).getFirstChild.getData() );
    subAttr = requirements.item(k-1).getAttributes.getNamedItem('sub');
    subs = getAttributeData( subAttr, subs );
    subRecursiveAttr = requirements.item(k-1).getAttributes.getNamedItem('sub-all');
    subsRecursive = getAttributeData( subRecursiveAttr, subsRecursive );
    branchAttr = requirements.item(k-1).getAttributes.getNamedItem('branch');
    branches = getAttributeData( branchAttr, branches );
    startupAttr = requirements.item(k-1).getAttributes.getNamedItem('startup');
    startup = getAttributeData( startupAttr, startup );
end
end

function data = getAttributeData( attr, data )
    if ~isempty( attr )
        data{end+1,1} = char( attr.getFirstChild.getData() );
    else
        data{end+1,1} = '';
    end
end
