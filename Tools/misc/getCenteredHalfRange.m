function range = getCenteredHalfRange( oldRange, newMidpoint )

lowerRange = linspace( newMidpoint, oldRange(1), 3 );
range(1) = lowerRange(2);
upperRange = linspace( newMidpoint, oldRange(end), 3 );
range(2) = upperRange(2);
