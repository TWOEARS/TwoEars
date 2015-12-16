function hashValue = generateHash(inputString)
% GENERATEHASH This function can be used to generate a MD5 hash
%   value for a given string.
%
% REQUIRED INPUTS:
%   inputString - String that should be converted.
%
% OUTPUTS:
%   hashValue - MD5 hash value

% Check inputs
p = inputParser();

p.addRequired('inputString', @ischar);
p.parse(inputString);

% Convert string to byte-array
byteString = java.lang.String(inputString);

% Generate an instance of the Java "Message Digest" class
javaMessageDigest = ...
    java.security.MessageDigest.getInstance('MD5');

% Append byte array to hash processor
javaMessageDigest.update(byteString.getBytes);

% Generate hash value and convert back to Matlab string format
byteHash = javaMessageDigest.digest();
byteHash = java.math.BigInteger(1, byteHash);
hashValue = char(byteHash.toString(16));
end