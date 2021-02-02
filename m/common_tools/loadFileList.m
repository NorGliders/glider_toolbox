function [ processed_files ] = loadFileList(filename)
% SETUPCONFIGURATION  Read configuration for processing glider data
%
%  Syntax:
%    [PROCESSED_FILES] = loadFilelist(FILENAME)

narginchk(1,1);

% Read file if it exists
if exist(filename, 'file')
    fid = fopen(filename,'r');
    [num_lines] = numLinesInFile(fid);
    processed_files = cell([num_lines,num_lines>0]);
    i = 0;
    frewind(fid)
    while ~feof(fid)
        tline = fgetl(fid);
        if ischar(tline)
            i = i+1;
            processed_files{i,1} = tline;
        end
    end
    fclose(fid);
else
    processed_files = {};
    disp('Processed file list does not exist');
end