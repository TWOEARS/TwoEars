function [RootNode, DocumentNode] = dbOpenXML(filename)
% open and validates xml file for audio-visual scene description
% 
% Parameters:
%   filename: filename of the XML-file (either locally or in the database)
%
% Return values:
%   RootNode: DOM-Node of root element in XML-Document
%   DocumentNode: DOM-Node of XML-Document
%
% See also: xml.dbGetFile xml.dbValidate xmlread

  filename = xml.dbValidate(filename);

  DocumentNode = xmlread(filename);
  RootNode = DocumentNode.getDocumentElement;
end