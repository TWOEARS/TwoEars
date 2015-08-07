function displayTwoEarsInfo(modus)
%displayTwoEarsInfo displays information about the Two!Ears Auditory Model
%
%   USAGE
%       displayTwoEarsInfo()
%       displayTwoEarsInfo('full')
%
%   INPUT PARAMETERS
%       modus   - could be 'small' or 'full' and decides how detailed the output
%                 will be

if nargin==0
    modus = 'small';
end

if strcmp('full', modus)
    fprintf(1, '\n');
    fprintf(1, ' __ __|              | ____|\n');
    fprintf(1, '    |\\ \\  \\   / _ \\  | __|    _` |  __| __|\n');
    fprintf(1, '    | \\ \\  \\ / (   |_| |     (   | |  \\__ \\\n');
    fprintf(1, '   _|  \\_/\\_/ \\___/ _)_____|\\__,_|_|  ____/\n');
    fprintf(1, '\n');
    fprintf(1, ' Two!Ears %s. Copyright 2015 the Two!Ears team.\n', getTwoEarsVersion);
    fprintf(1, '\n');
    fprintf(1, ' For documentation go to: http://twoears.aipa.tu-berlin.de/doc/\n');
    fprintf(1, '\n');
    fprintf(1, ' The Two!Ears team are:\n');
    fprintf(1, '\n');
    fprintf(1, '   Sylvain Argentieri, UPMC\n');
    fprintf(1, '   Jens Blauert, RUB\n');
    fprintf(1, '   Jonas Braasch, Rensselaer\n');
    fprintf(1, '   Guy Brown, USFD\n');
    fprintf(1, '   Benjamin Cohen-L''hyver, UPMC\n');
    fprintf(1, '   Patrick Danes, LAAS\n');
    fprintf(1, '   Torsten Dau, DTU\n');
    fprintf(1, '   Remi Decorsiere, DTU\n');
    fprintf(1, '   Thomas Forgue. LAAS\n');
    fprintf(1, '   Bruno Gas, UPMC\n')
    fprintf(1, '   Chungeun Kim, TU/e\n');
    fprintf(1, '   Armin Kohlrausch, TU/e\n');
    fprintf(1, '   Dorothea Kolossa, RUB\n');
    fprintf(1, '   Ning Ma, USFD\n');
    fprintf(1, '   Tobias May, DTU\n');
    fprintf(1, '   Johannes Mohr, TUB\n');
    fprintf(1, '   Klaus Obermayer, TUB\n');
    fprintf(1, '   Ariel Podlubne, LAAS\n');
    fprintf(1, '   Alexander Raake, TUIl\n');
    fprintf(1, '   Christopher Schymura, RUB\n');
    fprintf(1, '   Sascha Spors, URO\n');
    fprintf(1, '   Jalil Taghia, TUB\n');
    fprintf(1, '   Ivo Trowitsch, TUB\n');
    fprintf(1, '   Thomas Walther, RUB\n');
    fprintf(1, '   Hagen Wierstorf, TUB\n');
    fprintf(1, '   Fiete Winter, URO\n');
    fprintf(1, '\n');
elseif strcmp('small', modus)
    fprintf(1, 'Two!Ears %s. Copyright 2015 the Two!Ears team.\n', getTwoEarsVersion);
else
    error('''modus'' has to be ''full'' or ''small''.');
end

% vim: set sw=4 ts=4 et tw=90:
