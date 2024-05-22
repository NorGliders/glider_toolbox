function [ new_T ] = createXbdTable(existing_T, files)
% CREATEXBDTABLE  Initialize table for processed xbds
% processed_xbds = createXbdTable(processed_xbds, total_xbds);
%  Syntax:
%    [PROCESSED_XBDS] = createXbdTable()
%
% col_names = {'xbd_name','ext','segment','dos_name','dba_name','filesize','lines','dba','dat','plot_file'}

narginchk(2,2);

[~, segment, ext] = cellfun(@fileparts,files,'UniformOutput',false);
xbd_name = strcat(segment,ext);
ext = cellfun(@(x) x(2:end),ext,'UniformOutput',false);

% Specify column names and types
opts.VariableNames = ["segment", "dos_name", "ext", "dba_name", "file_start", "mission_name", "filesize", "lines", "dba", "dat", "plot_file"];
opts.VariableTypes = ["string", "string", "string", "string", "string", "string", "double", "double", "double", "double", "double"];

new_T = table('Size',[numel(xbd_name) 11],'VariableNames',opts.VariableNames,'VariableTypes',opts.VariableTypes,'RowNames',xbd_name);
new_T.segment = segment;
new_T.ext = ext;

% If a table already exists append new table to it and sort
if numel(existing_T) > 0
    new_T = [existing_T; new_T];
end
new_T = sortrows(new_T);