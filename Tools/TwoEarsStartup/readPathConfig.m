function partPath = readPathConfig( rcXmlFileName, tagname )
%READPARTCONFIG returns the path for the specififed Two!Ears part
%
% readPartConfig( configXmlFile, partName ) returns the path for the Two!Ears
% software part partName as specified in the configXmlFile.

rcXml = xmlread( rcXmlFileName );

try
    partPath = char( rcXml.getElementsByTagName( tagname ).item(0).getFirstChild.getData );
catch ME
    error('Your Two!Ears pathes file %s misses an entry for "%s"',rcXmlFileName,tagname);
end
