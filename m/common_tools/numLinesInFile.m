function [num_lines] = numLinesInFile(fid)
% numLinesInFile Get the number of lines in a file from input file indentifier, e.g for preallocation
%
%  Syntax:
%    [NUM_LINES] = NUMLINESINFILE(fid)

narginchk(1,1);

% Loop through file
num_lines = 0;
while ~feof(fid)
    tline = fgetl(fid);
    if ischar(tline)
        num_lines = num_lines + 1;
    end
end
