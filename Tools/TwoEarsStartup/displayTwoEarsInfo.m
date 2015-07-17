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
    fprintf(1, '   Jens Blauert, Ruhr University Bochum\n');
    fprintf(1, '   Jonas Braasch, Rensselaer\n');
    fprintf(1, '   Guy Brown, University of Sheffield\n');
    fprintf(1, '   Benjamin Cohen-L''hyver, UPMC\n');
    fprintf(1, '   Patrick Danes, LAAS\n');
    fprintf(1, '   Torsten Dau, Technical University of Denmark\n');
    fprintf(1, '   Remi Decorsiere, Technical University of Denmark\n');
    fprintf(1, '   Thomas Forgue. LAAS\n');
    fprintf(1, '   Bruno Gas, UPMC\n')
    fprintf(1, '   Chungeun Kim, Eindhoven University of Technology\n');
    fprintf(1, '   Armin Kohlrausch, Eindhoven University of Technology\n');
    fprintf(1, '   Dorothea Kolossa, Ruhr University Bochum\n');
    fprintf(1, '   Ning Ma, University of Sheffield\n');
    fprintf(1, '   Tobias May, Technical University of Denmark\n');
    fprintf(1, '   Johannes Mohr, TU Berlin\n');
    fprintf(1, '   Klaus Obermayer, TU Berlin\n');
    fprintf(1, '   Ariel Podlubne, LAAS\n');
    fprintf(1, '   Alexander Raake, TU Ilmenau\n');
    fprintf(1, '   Christopher Schymura, Ruhr University Bochum\n');
    fprintf(1, '   Sascha Spors, University Rostock\n');
    fprintf(1, '   Jalil Taghia, TU Berlin\n');
    fprintf(1, '   Ivo Trowitsch, TU Berlin\n');
    fprintf(1, '   Thomas Walther, Ruhr University Bochum\n');
    fprintf(1, '   Hagen Wierstorf, TU Berlin\n');
    fprintf(1, '   Fiete Winter, University Rostock\n');
    fprintf(1, '\n');
elseif strcmp('small', modus)
    fprintf(1, 'Two!Ears %s. Copyright 2015 the Two!Ears team.\n', getTwoEarsVersion);
else
    error('''modus'' has to be ''full'' or ''small''.');
end

% vim: set sw=4 ts=4 et tw=90:
