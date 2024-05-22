function [ logs_table ] = updateLogTable(logs_table, new_files, glider)
% UPDATELOGTABLE  Initialize table for processed xbds
% processed_xbds = updateXbdTable(processed_xbds, total_xbds);
%  Syntax:
%    [PROCESSED_XBDS] = updateLogTable()

narginchk(3,3);

log_struct = struct();

% Read each log file and save info to srfStruct file
for i = 1:numel(new_files)
    file = new_files{i};
    [~, filename, ext] = fileparts(file);
    filename = [filename ext];
    log_struct = readSlocumLogFile(file, glider);
    this_log_table = struct2table(log_struct,'AsArray',1);
    this_log_table.Properties.RowNames = this_log_table.log_file;
    this_log_table.log_file = [];
    
    % Create a table
    if ~numel(logs_table)
        % Table haas not yet been created, process first log file and initialise it
        logs_table = this_log_table;
    else
        % Check T and T_new have same rownames if not append columns
        logs_varnames = logs_table.Properties.VariableNames;
        this_log_varnames = this_log_table.Properties.VariableNames;
        
        if ~isequal(logs_varnames',this_log_varnames')
            
            % If there are sensors in this log file that are not in the
            % table add new column to table and backfill those values
            for j = 1:numel(this_log_varnames)
                if ~ismember(this_log_varnames{j},logs_varnames)
                    % Add cloumn
                    logs_table.(this_log_varnames{j}) = nan(size(logs_table,1),1);
                    disp('add col to main logs table')
                end
            end
            
            % If there are sensors in the table that are not in the log
            % file add new fields and set to appropriate empty value
            for j = 1:numel(logs_varnames)
                if ~ismember(logs_varnames{j}, this_log_varnames)
                    % Add column
                    disp(['add col to this logs table ' logs_varnames{j}])
                    this_log_table.(logs_varnames{j}) = NaN;
                end
            end
        end
        
        % Check for duplicate segments (indicating multiple call ins) find best one
        %         this_log_segment = this_log_table{:,'segment_name'};
        %         logs_segments = logs_table{:,'segment_name'};
        %         if ismember(this_log_segment, logs_segments) && ~ismissing(this_log_segment)
        %             disp(['Multiple log files for segment: ' char(this_log_segment)])
        %             % Use the one that has less NaNs
        %             existing_log_row = logs_table(logs_table.segment_name char(this_log_segment),:);
        %
        %
        %             FinalTable = logs_table(strcmp(logs_table.segment_name, char(this_log_segment))
        %
        %             % Number of NaN's in exisiting row
        %             n_exisitng = sum(ismissing(existing_log_row{:,:}));
        %             % Number of NaN's in exisiting row
        %             n_new = sum(ismissing(this_log_table{:,:}));
        %             if n_new < n_exisitng
        %                 logs_table(char(this_log_segment),:) = this_log_table;
        %                 disp(['Overwriting original'])
        %             end
        %         else

        logs_table = [logs_table;this_log_table];
    end
end

% Set the dimensions to this values, essential when writing to text file,
% this will be name of column
logs_table.Properties.DimensionNames{1}='LogFileNames';

