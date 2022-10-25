function [full_file_list, file_list] = getDirList(my_dir, file_type)
% FILE_LIST = GETDIRLIST(MY_DIR, FILE_TYPE)
% Returns a cell of files in directory MY_DIR of file type FILE_TYPE
% If no file type is specified find all files

if nargin < 2
    file_type = '*';
end

files_struct = dir([my_dir '/*.' file_type]);
file_list = {files_struct.name}';
full_file_list = strcat([my_dir '/'],file_list);