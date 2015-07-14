function range = getNewLogRange( oldRange, newmidpoint )

lowerRange = linspace( newmidpoint, oldRange(1), 3 );
range(1) = lowerRange(2);
upperRange = linspace( newmidpoint, oldRange(end), 3 );
range(2) = upperRange(2);
