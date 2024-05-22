function num_ext = get_ext_number(list_ext,ext_type)
% GET_EXT_NUMBER  Get number of specific file types in cell array
% num_ext = get_ext_number(list_ext,ext_type)
%  Syntax:
%    num_ext = GET_EXT_NUMBER(list_ext,ext_type)
%

ext = cellfun(@(x) strcmp(x,ext_type),list_ext,'UniformOutput',false);
num_ext = sum(cell2mat(ext));
