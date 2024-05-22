function slocum_web_monitor(cfg)
%-----------------------------------------------------------------------------------------
% slocum_web_monitor(cfg)
%
% [] = slocum_web_monitor(cfg)
%
% Main script for the NIWA Real-Time processing program for Slocum gliders
% toolbox
%
% Input arguments:
% cfg       - Configuration structure output by parse_config_file.m
%
% Create segment name list (i.e not ext) of processedTbd.txt, prevent 
% loading different files types of the same segment. If the files types
% arrive at the same time priority is EBD then NBD then TBD. Otherwise it
% first file come, first used. With need to process entire dataset to over
% write tbd files with ebd or nbd
%
% TODO:     - project_plan.kml
%           - hazzards.kml
%           - generate_queued_waypoints.m is disabled for now work out
%             process behind this
%           - srfStruct_to_kml.m copy all files to www server then edit
%             paths in this script - For now this is disabled
%           - SSH/SFTP transferr!
%
% NIWA Slocum toolbox
%
% History:
% 2014        Ben Hollings (ANFOG)
% 2015-May-15 FE Adapted for the NIWA Slocum toolbox
% 2015-Nov-18 FE
% 2016-Sep-19 FE Update current_waypoints.kml: Check file was created after the start of mission
% 2017-May-25 FE Read in logs from different dockserver (user has to
% manually transfer the files)
%-----------------------------------------------------------------------------------------


%% --- Setup ---
STARTTIME       = datenum(cfg.DEPLOY_DATE);
MISSION         = cfg.MISSION;
GLIDER          = cfg.GLIDER;

screen_print('minor',['STARTING         ' mfilename])
screen_print('blank',['Glider:          ',GLIDER])
screen_print('blank',['Mission:         ',MISSION])
screen_print('blank',['Deployment date: ',cfg.DEPLOY_DATE ' UTC'])

% --- Define input folders ---
% DS_ARCHIVE_FW       = [cfg.DS_DIR_FW,'\to-glider']; % freewave only
% DS_DATA_DIR_IRD     = [cfg.DS_DIR_IRD,'\from-glider'];
% DS_DATA_DIR_FW      = [cfg.DS_DIR_FW,'\from-glider'];
% DS_LOG_DIR_IRD      = [cfg.DS_DIR_IRD,'\logs'];
% DS_LOG_DIR_FW       = [cfg.DS_DIR_FW,'\logs'];

%DS_ARCHIVE_FW       = [cfg.DS_DIR_FW,'\to-glider']; % freewave only
DS_DATA_DIR         = [cfg.DS_DIR,'binary'];
DS_LOG_DIR          = [cfg.DS_DIR,'logs'];

% --- Define output folders ---
OUT_DIR        = fullfile(cfg.PROJECT_DIR);
BIN_DIR        = fullfile(OUT_DIR,'binary');
CAC_DIR        = fullfile(OUT_DIR,'binary','cache');        
LOG_DIR        = fullfile(OUT_DIR,'logs');
DAT_DIR        = fullfile(OUT_DIR,'ascii');
SURF_DIR       = fullfile(OUT_DIR,'surface');
COMB_MAT_DIR   = fullfile(OUT_DIR,'comb_mat');
RT_NETCDF_DIR  = fullfile(OUT_DIR,'rt_netcdf');
SEG_DIR        = fullfile(OUT_DIR,'segments');
ENG_TR_DIR     = fullfile(OUT_DIR,'eng_transects');
SCI_TR_DIR     = fullfile(OUT_DIR,'sci_transects');
CMD_DIR        = fullfile(OUT_DIR,'cmdDir');
WEB_DIR        = fullfile(cfg.WEB_DIR);
% WEB_ENG_TR_DIR = fullfile(WEB_DIR,'gliders',GLIDER,'eng_transects');
% WEB_SCI_TR_DIR = fullfile(WEB_DIR,'gliders',GLIDER,'sci_transects');
% WEB_SURF_DIR   = fullfile(WEB_DIR,'gliders',GLIDER,'surface');

% --- Check if input directories exist, if not exit from program ---
if ~exist(DS_DATA_DIR,'dir'), disp(['Can not find iridium directory ' DS_DATA_DIR ', exiting.']),   return,   end;
if ~exist(DS_LOG_DIR,'dir'),  disp(['Can not find freewave directory ' DS_LOG_DIR ', exiting.']),    return,   end;

% --- Check if output directories exist, if not, create ---
if ~exist(OUT_DIR,'dir'),           screen_print('blank',['Creating: ',OUT_DIR]),         mkdir(OUT_DIR),   end;
if ~exist(BIN_DIR,'dir'),           screen_print('blank',['Creating: ',BIN_DIR]),         mkdir(BIN_DIR),   end;
if ~exist(LOG_DIR,'dir'),           screen_print('blank',['Creating: ',LOG_DIR]),         mkdir(LOG_DIR),   end;
if ~exist(DAT_DIR,'dir'),           screen_print('blank',['Creating: ',DAT_DIR]),         mkdir(DAT_DIR),   end;
if ~exist(SURF_DIR,'dir'),          screen_print('blank',['Creating: ',SURF_DIR]),        mkdir(SURF_DIR),   end;
if ~exist(COMB_MAT_DIR,'dir'),      screen_print('blank',['Creating: ',COMB_MAT_DIR]),    mkdir(COMB_MAT_DIR),   end;
if ~exist(RT_NETCDF_DIR,'dir'),     screen_print('blank',['Creating: ',RT_NETCDF_DIR]),   mkdir(RT_NETCDF_DIR),   end;
if ~exist(SEG_DIR,'dir'),           screen_print('blank',['Creating: ',SEG_DIR]),         mkdir(SEG_DIR),   end;
if ~exist(ENG_TR_DIR,'dir'),        screen_print('blank',['Creating: ',ENG_TR_DIR]),      mkdir(ENG_TR_DIR),   end;
if ~exist(SCI_TR_DIR,'dir'),        screen_print('blank',['Creating: ',SCI_TR_DIR]),      mkdir(SCI_TR_DIR),   end;
if ~exist(CMD_DIR,'dir'),           screen_print('blank',['Creating: ',CMD_DIR]),         mkdir(CMD_DIR),   end;
% if ~exist(WEB_DIR,'dir'),           screen_print('blank',['Creating: ',WEB_DIR]),         mkdir(WEB_DIR),   end;
% if ~exist(WEB_ENG_TR_DIR,'dir'),    screen_print('blank',['Creating: ',WEB_ENG_TR_DIR]),  mkdir(WEB_ENG_TR_DIR),   end;
% if ~exist(WEB_SCI_TR_DIR,'dir'),    screen_print('blank',['Creating: ',WEB_SCI_TR_DIR]),  mkdir(WEB_SCI_TR_DIR),   end;
% if ~exist(WEB_SURF_DIR,'dir'),      screen_print('blank',['Creating: ',WEB_SURF_DIR]),    mkdir(WEB_SURF_DIR),   end;

% --- Check if mission kmz file exists, if not, create ---
if ~exist(fullfile(OUT_DIR,[GLIDER,'_',MISSION,'.kmz']),'file')
    disp([getUTC ': Creating mission KMZ file...']);
    create_mission_kmz(OUT_DIR,cfg);
end

% --- Check if project_plan.kml file exists, if not, copy from OPS_FILES ---
kmzFile = 'project_plan-END1805.kmz';
if ~exist(fullfile(OUT_DIR,kmzFile),'file')
    if exist(fullfile(cfg.OP_RESOURCES_DIR,'maps',kmzFile),'file')
        disp([getUTC ': Copying project plan kmz file from Op-resources']);
        copyfile(fullfile(cfg.OP_RESOURCES_DIR,'maps',kmzFile),fullfile(OUT_DIR,kmzFile));
    else
        disp([getUTC ': No project plan KMZ file available - CREATE ONE!']);
    end
end

% --- Check if hazzards.kml file exists in dir, if not, copy from OPS_FILES ---
kmzFile = 'hazards-END1805.kmz';
if ~exist(fullfile(OUT_DIR,kmzFile),'file')
    if exist(fullfile(cfg.OP_RESOURCES_DIR,'maps',kmzFile),'file')
        disp([getUTC ': Copying hazards kmz file from Op-resources']);
        copyfile(fullfile(cfg.OP_RESOURCES_DIR,'maps',kmzFile),fullfile(OUT_DIR));
    else
        disp([getUTC ': No hazzards KMZ file available - CREATE ONE!']);
    end
end

% --- Update current_waypoints.kml ---
% TODO: does DS auto update archive every time we send a goto_l10.ma file?
% Find newest goto_l10.ma
% gotoFileInfo  = dir([DS_ARCHIVE_FW,'\*goto_l10.ma']);
% gotoFileNames = cell(size(gotoFileInfo,1),1);
% gotoFileTime  = nan(size(gotoFileInfo,1),1);
% if ~isempty(gotoFileInfo)
%     for ii=1:length(gotoFileInfo)
%         gotoFileNames{ii} = gotoFileInfo(ii).name;
%         gotoFileTime(ii)  = datenum(gotoFileInfo(ii).name(1:15),'yyyymmddTHHMMSS');
%     end
%     
%     nGoto              = find(gotoFileTime == max(gotoFileTime));
%     newestGotoFile     = gotoFileNames{nGoto};
%     newestGotoFileTime = gotoFileTime(nGoto);
%     
%     % Check file was created after the start of mission
%     if newestGotoFileTime > STARTTIME
%         if exist(fullfile(OUT_DIR,'current_waypoints.kml'),'file')
%             kmlInfo = dir(fullfile(OUT_DIR,'current_waypoints.kml'));
%             a = kmlInfo.datenum - (newestGotoFileTime + 8/24);
%             
%             if a < 0
%                 disp([getUTC ': Found GOTO file newer than current_wpt.kml, updating...']);
%                 generate_current_waypoints(cfg,newestGotoFile);
%             end
%         else
%             disp([getUTC ': current_wpt.kml does not exist, creating...']);
%             %generate_current_waypoints(cfg,newestGotoFile);
%         end
%     end
% else
%     disp([getUTC ': No new goto_l10.ma in Dockserver sub, current waypoints have not been altered or not been properly archived'])
% end


% --- Update queued_waypoints.kml
% generate_queued_waypoints(cfg);


%% --- Sync Wellseaglider and Freewave files ---
% NB: Files are synced from dockserver (wellseaglider) to ~\from-wellseaglider every 10min
% Archive - freewave only
% dirs_equal(DS_ARCHIVE_FW,CMD_DIR);

% Log files - iridium and freewave
%sync_files_fw_ird(DS_LOG_DIR_FW, DS_LOG_DIR_IRD, LOG_DIR);
dockserver_sync(DS_LOG_DIR,LOG_DIR)

% Binary files - iridium and freewave
% sync_files_fw_ird(DS_DATA_DIR_FW, DS_DATA_DIR_IRD, BIN_DIR);
dockserver_sync(DS_DATA_DIR,BIN_DIR)


%% --- Process Log Files ---
% --- Find new logs after 'startTime' and process creating srfStruct.dat ---
% Create list of all log files
directoryList = dir([LOG_DIR,'\*.log']);
n             = length(directoryList);

% Identify log files created after startTime
modTime = zeros(n,1);
for i=1:n
    dName      = directoryList(i).name;
    loc        = strfind(dName,'_20');
    dateText   = dName(loc+1:loc+15);
    modTime(i) = datenum(dateText,'yyyymmddTHHMMSS');
end
ind = find(modTime>STARTTIME);

% Cancel processing if there are no new files after starttime
% if isempty(ind)
%     disp('---------------------------------------------------------------------')
%     disp([getUTC,': FINISH ',mfilename, ' - no new files available after start time ' cfg.DEPLOY_DATE]);
%     disp('---------------------------------------------------------------------')
%     return
% end

% Cell of log files after startTime
logFiles = {directoryList(ind).name}';

clear 'ind' 'modTime' 'directorylist' 'n' 'loc' 'dname'

% Read processedLogs.txt if it exists
if exist(fullfile(OUT_DIR,'processedLogs.txt'),'file')
    screen_print('standard','LOADING Processed logs list');
    fid = fopen(fullfile(OUT_DIR,'processedLogs.txt'),'r');
    i=0;
    while 1
        tline= fgetl(fid);
        if ~ischar(tline), break, end
        i = i+1;
        processedLogs{i,1} = tline;
    end
    fclose(fid);
else
    processedLogs = {};
    disp([getUTC ': Processed logs list does not exist']);
end

% Create list of log files which exist and have not been processed
if exist('logFiles','var')
    j = 0;
    logFilesToProcess={};
    for i=1:length(logFiles)
        if sum(strcmp(logFiles{i},processedLogs)) == 0
            j = j + 1;
            logFilesToProcess{j,1} = logFiles{i,1};
        end
    end
    disp([getUTC ': Found ',num2str(length(logFilesToProcess)),' new log files to process...'])
end

% read_slocum_log
if ~isempty(logFilesToProcess)
    
    % Sort by date
    logFilesToProcess = sort(logFilesToProcess);
    % Read each log file and save info to srfStruct file
    for i = 1:length(logFilesToProcess)
        read_slocum_log(cfg, logFilesToProcess{i,1});
        % Add processed file to list
        fid = fopen(fullfile(OUT_DIR,'processedLogs.txt'),'a');
        fprintf(fid,[logFilesToProcess{i,1},'\n']);
        fclose(fid);
    end
    
    % Sort srfStruct order by timestamps
    load(fullfile(OUT_DIR,[GLIDER,'_srfStruct.mat']));
    srfTimet = [srfStruct.CurrentTimeNum]';
    srfStructIn = srfStruct;
    clear('srfStruct');
    
    % [~,ind] = sort(srfTimet); %Sort with time?
    [~, ind, ~] = unique(srfTimet);
    
    for i=1:length(srfStructIn)
        srfStruct(i,1) = srfStructIn(ind(i),1);
    end
    
    % Save srfStruct to root
    save(fullfile(OUT_DIR,[GLIDER,'_srfStruct.mat']),'srfStruct');
    disp([getUTC ': Saving updated ' GLIDER '_srfStruct.mat'])
    
    % Save surface data to active_gliders_surface.mat ad .json
    save_surf_struct(cfg,srfStruct());
end

% % --- Create KML from srfStruct (only if new data)
% if numel(logFilesToProcess)>0
%     srfStruct_to_kml(cfg);
% end

% --- Create battery plots (only if new data) ---
if numel(logFilesToProcess)>0
    sl_plot_battery_diagnostics(cfg);
%     sl_plot_battery(cfg);
%     sl_plot_power(cfg);
end

% --- Create SRF data (health) plots ---
if numel(logFilesToProcess)>0
    sl_plot_srfStruct(cfg)
end

% --- Create position text file from srfStruct (only if new data)----
if cfg.WRITE_POSITION_FEED == 1
    if numel(logFilesToProcess)>0
        write_niwa_position_feed_txt(cfg);
    end
end


%% --- Process SBD Files ---
% --- Rename from DOS 8.3 format
% startDir = pwd;
% cd(BIN_DIR);
% screen_print('blank','Rename file in DOS 8.3 format')
% renameExePath = fullfile(cfg.APP_DIR,'rename_dbd_files.exe');
% [status, Result] = dos(['dir | call ', renameExePath, ' -s']);
% cd(startDir)

% --- Create list of all files
% Priority: DBD > MBD > SBD
directoryListSbd = dir([BIN_DIR '\' GLIDER '*.sbd']);
directoryListMbd = dir([BIN_DIR '\' GLIDER '*.mbd']);
directoryListDbd = dir([BIN_DIR '\' GLIDER '*.dbd']);

% List SBD and DBD files
sbdFiles = {directoryListSbd.name}';
mbdFiles = {directoryListMbd.name}';
dbdFiles = {directoryListDbd.name}';

% Get file name
[~,sbdName,~] = cellfun(@fileparts, sbdFiles, 'UniformOutput',false);
[~,mbdName,~] = cellfun(@fileparts, mbdFiles, 'UniformOutput',false);
[~,dbdName,~] = cellfun(@fileparts, dbdFiles, 'UniformOutput',false);

% If there exist sbd, mdb and/or dbd files of the same segment remove the
% sbd file then the mbd file
locA = ismember(sbdName,dbdName);
% locB = ismember(sbdName,mbdName);
% sbdFiles((locA+locB)>0) = [];
sbdFiles((locA)>0) = [];

% locC = ismember(mbdName,dbdName);
% mbdFiles(locC) = [];

% sbdFiles = [sbdFiles; mbdFiles; dbdFiles];
sbdFiles = [sbdFiles; dbdFiles];
n = length(sbdFiles);

if n==0
    disp('---------------------------------------------------------------------')
    disp([getUTC,': FINISH ',mfilename, ' - no new sbd files available']);
    disp('---------------------------------------------------------------------')
    return
end

% --- Find the start date of the mission
for i = 1:n
    loc        = strfind(sbdFiles{i},'-');
    yyyy       = str2double(sbdFiles{i}(loc(1)+1:loc(2)-1));
    jDay       = str2double(sbdFiles{i}(loc(2)+1:loc(3)-1)) + 1; % TWR uses a zero-based julian day
    modTime(i) = datenum(yyyy,0,jDay,0,0,0);
end

% --- Use sbd files on or after the startTime DAY
ind      = (modTime>=datenum(datestr(STARTTIME,'yyyy-mm-dd'),'yyyy-mm-dd'));
sbdFiles = sort(sbdFiles(ind));

% --- Read processedSbd.txt if it exists
if exist(fullfile(OUT_DIR,'processedSbd.txt'),'file')
    disp([getUTC ': LOADING Processed sbd list']);
    fid = fopen(fullfile(OUT_DIR,'processedSbd.txt'),'r');
    i=0;
    while 1
        tline= fgetl(fid);
        if ~ischar(tline), break, end
        i=i+1;
        processedSbd{i,1}=tline;
    end
    fclose(fid);
else
    processedSbd={};
end

% Create segment name list (no ext) of processedSbd.txt, prevent 
% loading different files types of the same segment. If the files types
% arrive at the same time priority is DBD then MBD then SBD. Otherwise its
% first file come, first used. Will need to process entire dataset to over
% write sbd files with dbd or mbd
[~,sbdFilesNoExt,~] = cellfun(@fileparts, sbdFiles, 'UniformOutput',false);
[~,processedSbdNoExt,~] = cellfun(@fileparts, processedSbd, 'UniformOutput',false);


% --- Create list of SBD files which exist and have not been processed
if exist('sbdFilesNoExt','var')
    j = 0;
    sbdFilesToProcess={};
    for i = 1:length(sbdFilesNoExt)
        if sum(strcmp(sbdFilesNoExt{i},processedSbdNoExt)) == 0
            j = j+1;
            % Switch back to sbdFiles cell rather than sbdFilesNoExt so
            % correct file is called
            sbdFilesToProcess{j,1} = sbdFiles{i,1};
        end
    end
    disp([getUTC ': Found ',num2str(length(sbdFilesToProcess)),' new sbd files to process...']);
end

%% --- Convert each SBD file
startDir = pwd;
cd(BIN_DIR);

for i = 1:length(sbdFilesToProcess)
    try
        screen_print('log',['Converting binary file: ' sbdFilesToProcess{i,1} ' to .mat and .asc'])

        bdFileName = fullfile(BIN_DIR,sbdFilesToProcess{i,1});
        [~,~,ext] = fileparts(sbdFilesToProcess{i,1});
        
        % Run dbd2asc.exe to get variables and units from header of binary file
        switch ext
            case {'.sbd','.mbd'}
                command            = ['"', cfg.APP_DIR,'\', 'dbd2asc" ','"', bdFileName, '"'];
                [~, result]        = system(command);
                if contains(result, 'Can''t open cache file')
                    h = strfind(result, 'Can''t open cache file');
                    h1 = strfind(result, '.CAC');
                    cache_file = result(h:h1+3);
                    ME = MException('SlocumError:CacheFileNotPresent', cache_file);
                    throw(ME);
                end
                h                   = find(result < 30);
                tmp1                = textscan(result(h(14):h(15)),'%s');
                tmp2                = textscan(result(h(15):h(16)),'%s');
                sbdVariableList     = [tmp1{:} tmp2{:}];
                origSbdVariableList = sbdVariableList; % may use in plotting
                disp([repmat(' ',1,23) 'Contains variables:'])
                disp([repmat('                       ',size(sbdVariableList,1),1) char(sbdVariableList{:,1})])
            case '.dbd'
                % dbd file
                disp([repmat(' ',1,23) 'DBD file, may take a while.......'])
        end
        
        % Run dbd2asc.exe to convert binary file to ascii
        tic;
        command = ['dir /b ', '"', bdFileName, '"', ' | ', '"', cfg.APP_DIR, '\dbd2asc" -c ', '"', CAC_DIR, '"  -s -o | ', '"', cfg.APP_DIR, '\dba2_orig_matlab"'];
        
        [~, result] = system(command);
        if contains(result, 'Can''t open cache file')
            h = strfind(result, 'Can''t open cache file');
            h1 = strfind(result, '.CAC');
            cache_file = result(h:h1+3);
            ME = MException('SlocumError:CacheFileNotPresent', cache_file);
            throw(ME);
        elseif contains(result, 'Error from write_asc_data()')
            ME = MException('SlocumError:ErrorFromWriteAscData', result);
            throw(ME);
        end
        disp([repmat(' ',1,23) 'Binary file conversion, elasped time is ' num2str(toc) ' seconds' ])
        scriptName  = result(1:size(result,2) - 3);
        segName     = scriptName(1:end-4);
        datFileName = [scriptName,'.dat'];
        mFileName   = [scriptName,'.m'];
        disp([repmat(' ',1,23) 'Created files: ' datFileName ' and ' mFileName]);
        
        % Load data file  -remove this later
        run(scriptName);
        
        % Save to sbd mission data
        if exist(fullfile(OUT_DIR,[GLIDER,'_sbdData.mat']),'file')
            
            % Load mission data
            load(fullfile(OUT_DIR,[GLIDER,'_sbdData.mat']));
            
            % If DBD read in all variables in SBD_VARIABLE_LIST
            if strcmp(ext,'.dbd')
                tempData = data;
                sbdVariableList = SBD_VARIABLE_LIST;
                clear data
                % Prepopulate new array with the number of samples in segment
                % Flight and number of sensors in main SBD_VARIABLE_LIST
                [m,~] = size(tempData);
                n = length(SBD_VARIABLE_LIST);
                data = ones(m,n)*NaN;
                for ind = 1:length(SBD_VARIABLE_LIST)
%                     if any(ismember({'drv_m_gps_lon', 'drv_m_gps_lat'},SBD_VARIABLE_LIST{ind,1}))
%                         data(:,ind) = eval(SBD_VARIABLE_LIST{ind,1});
%                     else
                        data(:,ind) = tempData(:,eval(SBD_VARIABLE_LIST{ind,1}));
%                     end
                end
            end
            
%             % If MBD read in all variables
%             if strcmp(ext,'.dbd')
%                 tempData = data;
%                 sbdVariableList = SBD_VARIABLE_LIST;
%                 clear data
%                 % Prepopulate new array with the number of samples in segment
%                 % Flight and number of sensors in main SBD_VARIABLE_LIST
%                 [m,~] = size(tempData);
%                 n = length(SBD_VARIABLE_LIST);
%                 data = ones(m,n)*NaN;
%                 for ind = 1:length(SBD_VARIABLE_LIST)
% %                     if any(ismember({'drv_m_gps_lon', 'drv_m_gps_lat'},SBD_VARIABLE_LIST{ind,1}))
% %                         data(:,ind) = eval(SBD_VARIABLE_LIST{ind,1});
% %                     else
%                         data(:,ind) = tempData(:,eval(SBD_VARIABLE_LIST{ind,1}));
% %                     end
%                 end
%             end
            
            if isequal(SBD_VARIABLE_LIST,sbdVariableList)
                % If list of variables is the same and in same order, easy:
                sbdData = data;
                disp([repmat(' ',1,23) 'Binary file variable list same as original, appending'])
            else
                % List of variables has been changed, time to think....
                % Find out what is where
                disp([repmat(' ',1,23) 'Binary file variable list has changed, sorting'])
                orig = SBD_VARIABLE_LIST(:,1);
                new = sbdVariableList(:,1);
                
                % Prepopulate new array
                sbdData = ones(size(data))*NaN;
                % Loop through variables of orig add data from new if they exist
                for ind = 1:numel(orig)
                    if exist(orig{ind},'var')
                        sbdData(:,ind) = data(:,eval(orig{ind}));
                    else
                        % If variable doesn't exist in current data fill with NaN's.
                        sbdData(:,ind) = NaN;
                    end
                end
                
                % Add new variables SBDDATA and SBD_VARIABLE_LIST if required
                if numel(new) > numel(orig)
                    [lac, ~]                            = ismember(new,orig);
                    SBDDATA(:,numel(orig)+1:numel(new)) = NaN;
                    tmp1                                = [SBD_VARIABLE_LIST(:,1); sbdVariableList(~lac,1)];
                    tmp2                                = [SBD_VARIABLE_LIST(:,2); sbdVariableList(~lac,2)];
                    SBD_VARIABLE_LIST                   = [tmp1 tmp2];
                    
                    % Add data from new variables to sbddata
                    lineno = 0;
                    for ind = 1:length(lac)
                        if ~lac(ind)
                            lineno = lineno + 1;
                            sbdData(:,numel(orig)+lineno) = data(:,eval(new{ind}));
                        end
                    end
                end
            end
            
            % Combine data from current dive with mission data
            SBDDATA = vertcat(SBDDATA,sbdData);
            % First column is alway m_present_time so sort columns with time
            SBDDATA = sortrows(SBDDATA,1);
            disp([repmat(' ',1,23) 'Concatenating this segment to mission time-series']);
            
        else
            % No mission data currently exists (first data file!) current dive data becomes mission data
            % First re-organise so time is in first column
            if strcmp(ext,'.dbd')
                % Load a standard varlist and read in those
                load('sbdVariableList-STD.mat');
                [m, ~] = size(data);
                sbdData = ones(m,length(sbdVariableList))*NaN;
                % Loop through variables of orig add data from new if they exist
                for ind = 1:length(sbdVariableList)
%                     if any(ismember({'drv_m_gps_lon', 'drv_m_gps_lat'},sbdVariableList{ind,1}))
%                         sbdData(:,ind) = eval(sbdVariableList{ind,1});
%                     else
                        sbdData(:,ind) = data(:,eval(sbdVariableList{ind,1}));
%                     end
                end
            else
                if m_present_time ~= 1
                    % Re-order if m_present_time is not first
                    data_time              = data(:,m_present_time);
                    data(:,m_present_time) = [];
                    sbdData                = [data_time data];
                    [~, tmp]               = ismember('m_present_time',sbdVariableList(:,1));
                    tmp2                   = sbdVariableList(tmp,:);
                    sbdVariableList(tmp,:) = [];
                    sbdVariableList        = [tmp2; sbdVariableList];
                end
            end
            % Current dive data becomes mission data
            SBDDATA = sbdData;
            % Save the initial list of vars. This will be added/ammended in the future as the sbdlist is edited
            SBD_VARIABLE_LIST = sbdVariableList;
            
        end
        
        % --- Save mission data file and list of variables ---
        save(fullfile(OUT_DIR,[GLIDER,'_sbdData.mat']),'SBDDATA','SBD_VARIABLE_LIST');
        disp([repmat(' ',1,23)  'Updating file ', fullfile(OUT_DIR,[GLIDER,'_sbdData.mat'])]);
        
        % --- Move files to ascii dir ---
        movefile(fullfile(BIN_DIR,datFileName),fullfile(DAT_DIR,datFileName));
        movefile(fullfile(BIN_DIR,mFileName),fullfile(DAT_DIR,mFileName));
        disp([repmat(' ',1,23) 'Moved files to asc directory']);
        
        % --- Check if segment directory exists & if not, create
        thisSegDir = fullfile(SEG_DIR,segName);
        if ~exist(thisSegDir,'dir')
            disp([repmat(' ',1,23) 'Creating: ',thisSegDir]);
            mkdir(thisSegDir);
            fid = fopen(fullfile(thisSegDir,'processing.txt'),'w');
            fprintf(fid, '%s %s Created segment directory\n', getUTC, mfilename);
            fprintf(fid, '%s %s seg_name = %s\n', getUTC, mfilename, segName);
            fprintf(fid, '%s %s SBD processing\n', getUTC, mfilename);
            fclose(fid);
        else
            fid = fopen(fullfile(SEG_DIR,'processing.txt'),'w');
            fprintf(fid, '%s %s flight binary file processing\n', getUTC, mfilename);
            fclose(fid);
        end
        
        % --- Diagnostic plotting of SBD data ---
        % Catch empty SBD files
        fid = fopen(fullfile(thisSegDir,'processing.txt'),'w');
        [m, ~] = size(data);
        min_num_samples = 50;
        if m < min_num_samples
            disp([repmat(' ',1,23) 'Less than ' num2str(min_num_samples) ' data points not creating flight segment plots'])
            fprintf(fid, '%s %s Less than %i data points not creating flight segment plots\n', mfilename, getUTC, min_num_samples);
            fclose(fid);
        else
            fprintf(fid, '%s %s Creating flight segment plots\n', mfilename, getUTC);
            % more to do here FE
            sl_plot_segment_sbd(cfg,segName,ext(2:end));
            fclose(fid);
        end
        clear('SBDDATA','data','sbdData','SBD_VARIABLE_LIST');
        
        % --- Add processed file to list ---
        fid = fopen(fullfile(OUT_DIR,'processedSbd.txt'),'a');
        fprintf(fid,[sbdFilesToProcess{i,1},'\n']);
        fclose(fid);
        
        % --- Plot SBD time series data (only on final loop) ---
        if i==numel(sbdFilesToProcess)
            sl_plot_mission_sbd(cfg);
        end
        
        % --- Clear workspace ---
        if exist('sbdVariableList','var')
            tmp = '';
            for ind = 1:size(sbdVariableList,1)
                tmp = [tmp ' ' sbdVariableList{ind,1}];
            end
            eval(['clear '  tmp])
        end
        clear global
    catch ME
        disp([getUTC,': ', ME.message])
    end
end
cd(startDir);
clear modTime directoryList n ind


%% --- Process  TBD Files ---
% --- Create list of all files
% Priority: EBD > NBD > TBD
directoryListTbd = dir([BIN_DIR,'\', GLIDER, '*.tbd']);
directoryListNbd = dir([BIN_DIR,'\', GLIDER, '*.nbd']);
directoryListEbd = dir([BIN_DIR,'\', GLIDER, '*.ebd']);

% List TBD, NBD and EBD files
tbdFiles = {directoryListTbd.name}';
nbdFiles = {directoryListNbd.name}';
ebdFiles = {directoryListEbd.name}';

% Get segment name
[~,tbdName,~] = cellfun(@fileparts, tbdFiles, 'UniformOutput',false);
[~,nbdName,~] = cellfun(@fileparts, nbdFiles, 'UniformOutput',false);
[~,ebdName,~] = cellfun(@fileparts, ebdFiles, 'UniformOutput',false);

% If there exist tbd, ndb and/or ebd files of the same segment remove the
% tbd file then the nbd file
locA = ismember(tbdName,ebdName);
% locB = ismember(tbdName,nbdName);
tbdFiles((locA)>0) = [];
locC = ismember(nbdName,ebdName);
nbdFiles(locC) = [];
tbdFiles = [tbdFiles; ebdFiles];
n = length(tbdFiles);

if n==0
    disp('---------------------------------------------------------------------')
    disp([getUTC,': FINISH ',mfilename, ' - no new tbd files available']);
    disp('---------------------------------------------------------------------')
    return
end

% --- Find the start date of the mission
for i = 1:n
    loc        = strfind(tbdFiles{i},'-');
    yyyy       = str2double(tbdFiles{i}(loc(1)+1:loc(2)-1));
    jDay       = str2double(tbdFiles{i}(loc(2)+1:loc(3)-1)) + 1;
    modTime(i) = datenum(yyyy,0,jDay,0,0,0);
end

% --- Use tbd files on or after the startTime DAY
ind      = (modTime>=datenum(datestr(STARTTIME,'yyyy-mm-dd'),'yyyy-mm-dd'));
tbdFiles = sort(tbdFiles(ind));

% --- Read processedTbd.txt if it exists
if exist(fullfile(OUT_DIR,'processedTbd.txt'),'file')
    screen_print('log',['LOADING Processed tbd list'])
    fid = fopen(fullfile(OUT_DIR,'processedTbd.txt'),'r');
    i=0;
    while 1
        tline= fgetl(fid);
        if ~ischar(tline), break, end
        i=i+1;
        processedTbd{i,1}=tline;
    end
    fclose(fid);
else
    processedTbd={};
end

% Create segment name list (no ext) of processedTbd.txt, prevent 
% loading different files types of the same segment. If the files types
% arrive at the same time priority is EBD then NBD then TBD. Otherwise its
% first file come, first used. Will need to process entire dataset to over
% write tbd files with ebd or nbd
[~,tbdFilesNoExt,~] = cellfun(@fileparts, tbdFiles, 'UniformOutput',false);
[~,processedTbdNoExt,~] = cellfun(@fileparts, processedTbd, 'UniformOutput',false);

% --- Create list of TBD files which exist and have not been processed
if exist('tbdFilesNoExt','var')
    j = 0;
    tbdFilesToProcess = {};
    for i=1:length(tbdFilesNoExt)
        if sum(strcmp(tbdFilesNoExt{i},processedTbdNoExt)) == 0
            j=j+1;
            % Switch back to tbdFiles cell rather than tbdFilesNoExt so
            % correct file is called
            tbdFilesToProcess{j,1} = tbdFiles{i,1};
        end
    end
    disp([getUTC ': Found ',num2str(length(tbdFilesToProcess)),' new tbd files to process...']);
end

%% --- Process  TBD Files ---
% --- Create list of all files
% Priority: EBD > NBD > TBD
directoryListTbd = dir([BIN_DIR,'\', GLIDER, '*.tbd']);
directoryListNbd = dir([BIN_DIR,'\', GLIDER, '*.nbd']);
directoryListEbd = dir([BIN_DIR,'\', GLIDER, '*.ebd']);

% List TBD, NBD and EBD files
tbdFiles = {directoryListTbd.name}';
nbdFiles = {directoryListNbd.name}';
ebdFiles = {directoryListEbd.name}';

% Get segment name
[~,tbdName,~] = cellfun(@fileparts, tbdFiles, 'UniformOutput',false);
[~,nbdName,~] = cellfun(@fileparts, nbdFiles, 'UniformOutput',false);
[~,ebdName,~] = cellfun(@fileparts, ebdFiles, 'UniformOutput',false);

% If there exist tbd, ndb and/or ebd files of the same segment remove the
% tbd file then the nbd file
locA = ismember(tbdName,ebdName);
locB = ismember(tbdName,nbdName);
tbdFiles((locA)>0) = []; %tbdFiles((locA+locB)>0) = [];
locC = ismember(nbdName,ebdName);
% nbdFiles(locC) = [];
tbdFiles = [tbdFiles; ebdFiles]; %tbdFiles = [tbdFiles; nbdFiles; ebdFiles];
n = length(tbdFiles);

if n==0
    disp('---------------------------------------------------------------------')
    disp([getUTC,': FINISH ',mfilename, ' - no new tbd files available']);
    disp('---------------------------------------------------------------------')
    return
end

% --- Find the start date of the mission
for i = 1:n
    loc        = strfind(tbdFiles{i},'-');
    yyyy       = str2double(tbdFiles{i}(loc(1)+1:loc(2)-1));
    jDay       = str2double(tbdFiles{i}(loc(2)+1:loc(3)-1)) + 1;
    modTime(i) = datenum(yyyy,0,jDay,0,0,0);
end

% --- Use tbd files on or after the startTime DAY
ind      = (modTime>=datenum(datestr(STARTTIME,'yyyy-mm-dd'),'yyyy-mm-dd'));
tbdFiles = sort(tbdFiles(ind));

% --- Read processedTbd.txt if it exists
if exist(fullfile(OUT_DIR,'processedTbd.txt'),'file')
    disp([getUTC ': LOADING Processed tbd list']);
    fid = fopen(fullfile(OUT_DIR,'processedTbd.txt'),'r');
    i=0;
    while 1
        tline= fgetl(fid);
        if ~ischar(tline), break, end
        i=i+1;
        processedTbd{i,1}=tline;
    end
    fclose(fid);
else
    processedTbd={};
end

% Create segment name list (no ext) of processedTbd.txt, prevent 
% loading different files types of the same segment. If the files types
% arrive at the same time priority is EBD then NBD then TBD. Otherwise its
% first file come, first used. Will need to process entire dataset to over
% write tbd files with ebd or nbd
[~,tbdFilesNoExt,~] = cellfun(@fileparts, tbdFiles, 'UniformOutput',false);
[~,processedTbdNoExt,~] = cellfun(@fileparts, processedTbd, 'UniformOutput',false);

% --- Create list of TBD files which exist and have not been processed
if exist('tbdFilesNoExt','var')
    j = 0;
    tbdFilesToProcess = {};
    for i=1:length(tbdFilesNoExt)
        if sum(strcmp(tbdFilesNoExt{i},processedTbdNoExt)) == 0
            j=j+1;
            % Switch back to tbdFiles cell rather than tbdFilesNoExt so
            % correct file is called
            tbdFilesToProcess{j,1} = tbdFiles{i,1};
        end
    end
    disp([getUTC ': Found ',num2str(length(tbdFilesToProcess)),' new tbd files to process...']);
end

disp('------------------------------')

%% --- Convert each TBD file
startDir = pwd;
cd(BIN_DIR);

for i = 1:length(tbdFilesToProcess)
    try
    screen_print('log',['Converting binary file: ' tbdFilesToProcess{i,1} ' to .mat and .asc'])
    
    bdFileName = fullfile(BIN_DIR,tbdFilesToProcess{i,1});
    [~,~,ext] = fileparts(tbdFilesToProcess{i,1});
    %origSbdVariableList = sbdVariableList;
    %origTbdVariableList = tbdVariableList;
    origTbdVariableList = '';
    
    % Run dbd2asc.exe to get variables and units from header of binary file
    switch ext
        case {'.tbd','.nbd'}
            command = ['"', cfg.APP_DIR,'\', 'dbd2asc" ','"', bdFileName, '"'];
            [~, result] = system(command);
            if contains(result, 'Can''t open cache file')
                h = strfind(result, 'Can''t open cache file');
                h1 = strfind(result, '.CAC');
                cache_file = result(h:h1+3);
                ME = MException('SlocumError:CacheFileNotPresent', cache_file);
                throw(ME);
            end
            h                   = find(result < 30);
            tmp1                = textscan(result(h(14):h(15)),'%s');
            tmp2                = textscan(result(h(15):h(16)),'%s');
            tbdVariableList     = [tmp1{:} tmp2{:}];
            origTbdVariableList = tbdVariableList; % may use in plotting
            disp([repmat(' ',1,23) 'Contains variables:'])
            disp([repmat('                       ',size(tbdVariableList,1),1) char(tbdVariableList{:,1})])
        case '.ebd'
            origTbdVariableList = load('tbdVariableList');
            origTbdVariableList = origTbdVariableList.tbdVariableList;
            disp([repmat(' ',1,23) 'EBD file, may take a while.......'])
    end
    
    % Run dbd2asc.exe to convert binary file to ascii
    tic;
    command = ['dir /b ', '"', bdFileName, '"', ' | ', '"', cfg.APP_DIR, '\dbd2asc" -c ', '"', CAC_DIR, '"  -s -o | ', '"', cfg.APP_DIR, '\dba2_orig_matlab"'];
    [~, result] = system(command);
    if contains(result, 'Can''t open cache file')
        h = strfind(result, 'Can''t open cache file');
        h1 = strfind(result, '.CAC');
        cache_file = result(h:h1+3);
        ME = MException('SlocumError:CacheFileNotPresent', cache_file);
        throw(ME);
    elseif contains(result, 'Error from write_asc_data()')
        ME = MException('SlocumError:ErrorFromWriteAscData', result);
        throw(ME);
    end
    disp([repmat(' ',1,23) 'Binary file conversion, elasped time is ' num2str(toc) ' seconds' ])
    scriptName  = result(1:size(result,2) - 3);
    segName     = scriptName(1:end-4);
    datFileName = [scriptName,'.dat'];
    mFileName   = [scriptName,'.m'];
    disp([repmat(' ',1,23) 'Created files ',datFileName, ' and ', mFileName]);
        
        % Load data file
        disp(pwd)
        disp(['run script: ' scriptName])
        run(scriptName);
        disp('ran script')
        % Save to tbd mission data
        if exist(fullfile(OUT_DIR,[GLIDER,'_tbdData.mat']),'file')
            
            % Load mission data file
            load(fullfile(OUT_DIR,[GLIDER,'_tbdData.mat']));
            
            % If EBD read in all variables in TBD_VARIABLE_LIST
            if strcmp(ext,'.ebd')
                tempData = data;
                tbdVariableList = TBD_VARIABLE_LIST;
                clear data
                % Prepopulate new array with the number of samples in segment
                % Science and number of sensors in main TBD_VARIABLE_LIST
                [m,~] = size(tempData);
                n = length(TBD_VARIABLE_LIST);
                data = ones(m,n)*NaN;
                for ind = 1:length(TBD_VARIABLE_LIST)
                    data(:,ind) = tempData(:,eval(TBD_VARIABLE_LIST{ind,1}));
                end
            end
            
            if isequal(TBD_VARIABLE_LIST,tbdVariableList)
                % If list of variables is the same and in same order, easy:
                tbdData = data;
                disp([repmat(' ',1,23) 'Binary file variable list same as original, appending'])
            else
                % List of variables has been changed, time to think....
                % Find out what is where
                disp([repmat(' ',1,23) 'Binary file variable list has changed, sorting'])
                orig = TBD_VARIABLE_LIST(:,1);
                new = tbdVariableList(:,1);
                
                % Prepopulate new array
                tbdData = ones(size(data))*NaN;
                % Loop through variables of orig add data from new if they exist
                for ind = 1:numel(orig)                                                 % Loop through variables of orig add data from new if they exist
                    if exist(orig{ind},'var')
                        tbdData(:,ind) = data(:,eval(orig{ind}));
                    else
                        tbdData(:,ind) = NaN;                                           % Else add NaN's.
                    end
                end
                
                % Add new variables TBDDATA and TBD_VARIABLE_LIST if required
                if numel(new) > numel(orig)
                    [lac, ~]                            = ismember(new,orig);
                    TBDDATA(:,numel(orig)+1:numel(new)) = NaN;
                    tmp1                                = [TBD_VARIABLE_LIST(:,1); tbdVariableList(~lac,1)];
                    tmp2                                = [TBD_VARIABLE_LIST(:,2); tbdVariableList(~lac,2)];
                    TBD_VARIABLE_LIST                   = [tmp1 tmp2];
                    
                    % Add data from new variables to tbddata
                    lineno = 0;
                    for ind = 1:length(lac)
                        if ~lac(ind)
                            lineno = lineno + 1;
                            tbdData(:,numel(orig)+lineno) = data(:,eval(new{ind}));
                        end
                    end
                end
            end
            
            % Combine data from current dive with mission data
            TBDDATA = vertcat(TBDDATA,tbdData);
            % First column is alway m_present_time so sort columns with time
            TBDDATA = sortrows(TBDDATA,1);
            disp([repmat(' ',1,23)  'Appending file ',fullfile(OUT_DIR,[GLIDER,'_tbdData.mat'])]);
            
        else
            % No mission data currently exists (first data file!) current dive data becomes mission data
            % First re-organise so time is in first column
            if strcmp(ext,'.ebd')

                
                % !!Check for specific sensors
                % tbdData = ones(m,length(tbdVariableList))*NaN;
                
                % Loop through variables of orig add data from new if they exist
                % Load a standard varlist and read in those
                %stdVars = load('tbdVariableList-STD.mat');
%                 nvars = 0;
%                 tbdVariableListEbd = {};
%                 for ind = 1:length(stdVars.tbdVariableList(:,1))
%                     if ismember(stdVars.tbdVariableList(ind,1),tbdVariableList(:,1))
%                         nvars = nvars + 1;
%                         tbdVariableListEbd(end+1,:) = stdVars.tbdVariableList(ind,:);
%                         %tbdData(:,ind) = data(:,eval(stdVars.tbdVariableList{ind,1}));
%                     end
%                 end
                m = length(origTbdVariableList);
                [n,~] = size(data);
                tbdData = ones(n,m)*NaN;
                tbdVariableList = origTbdVariableList;
                for ind = 1:length(origTbdVariableList)
                    tbdData(:,ind) = data(:,eval(tbdVariableList{ind}));
                end
                
            else
                if sci_m_present_time ~= 1
                    data_time                                   = data(:,sci_m_present_time);
                    data(:,sci_m_present_time)                  = [];
                    tbdData                                     = [data_time data];
                    [~, tmp]                                    = ismember('sci_m_present_time',tbdVariableList(:,1));
                    tmp2                                        = tbdVariableList(tmp,:);
                    tbdVariableList(tmp,:)                      = [];
                    tbdVariableList                             = [tmp2; tbdVariableList];
                end
            end
            
            % Current dive data becomes mission data
            TBDDATA = tbdData;
            % Save the initial list of vars. This will be added/ammended in the future as the tbdlist is edited
            TBD_VARIABLE_LIST  = tbdVariableList;
        end
        
        % Check for bad timestamp
        if any(ut2mt(TBDDATA(:,1)) < datenum(2000,1,1,0,0,0))
            dummy = (TBDDATA(:,1) < datenum(2000,1,1,0,0,0));
            TBDDATA(dummy,:) = [];
            disp([getUTC,': ' num2str(sum(dummy)) ' bad timestamp, removing lines ' segName])
        end
        
        % Save mission data file and list of variables
        save(fullfile(OUT_DIR,[GLIDER,'_tbdData.mat']),'TBDDATA','TBD_VARIABLE_LIST');
        disp([repmat(' ',1,23)  'Creating file ',fullfile(OUT_DIR,[GLIDER,'_tbdData.mat'])]);
        
        % --- Move files to ascii dir
        movefile(fullfile(BIN_DIR,datFileName),fullfile(DAT_DIR,datFileName));
        movefile(fullfile(BIN_DIR,mFileName),fullfile(DAT_DIR,mFileName));
        disp([repmat(' ',1,23) 'Moved files to asc directory']);
        
        % --- Check if segment directory exists & if not, create
        thisSegDir = [SEG_DIR,'\',segName];
        if ~exist(thisSegDir,'dir')
            disp([repmat(' ',1,22) 'Creating: ',thisSegDir]);
            mkdir(thisSegDir);
            fid = fopen(fullfile(thisSegDir,'processing.txt'),'w');
            fprintf(fid, '%s %s Created segment directory\n', mfilename, getUTC);
            fprintf(fid, '%s %s seg_name = %s\n', mfilename, getUTC, segName);
            fprintf(fid, '%s %s TBD processing\n', mfilename, getUTC);
            fclose(fid);
        else
            fid = fopen(fullfile(thisSegDir,'processing.txt'),'w');
            fprintf(fid, '%s %s TBD processing\n', mfilename, getUTC);
            fclose(fid);
        end
        
        % --- Diagnostic plotting of TBD data ---
        % Catch empty TBD files
        fid = fopen(fullfile(thisSegDir,'processing.txt'),'w');
        [m, ~] = size(data);
        if m < 10
            disp([repmat(' ',1,23) 'Less than 10 data points not creating science segment plots'])
            fprintf(fid, '%s %s Less than 10 data points not creating science segment plots\n', mfilename, getUTC);
            fclose(fid);
        else
            fprintf(fid, '%s %s Creating science segment plots\n', mfilename, getUTC);
            sl_plot_segment_tbd(cfg,segName,ext(2:end),tbdVariableList); %ext(2:end));
            fclose(fid);
        end
        clear('TBDDATA','data','tbdData','TBD_VARIABLE_LIST');
        
        % --- Add processed file to list ---
        fid = fopen(fullfile(OUT_DIR,'processedTbd.txt'),'a');
        fprintf(fid,[tbdFilesToProcess{i,1},'\n']);
        fclose(fid);
        
        % --- Plot TBD time series data for web display (only on final loop)
        if i==length(tbdFilesToProcess)
            sl_plot_mission_tbd(cfg);
        end
        
         % --- Clear workspace ---
        if exist('TbdVariableList','var')
            tmp = '';
            for ind = 1:size(TbdVariableList,1)
                tmp = [tmp ' ' TbdVariableList{ind}];
            end
            eval(['clear '  tmp])
        end
        clear global
 catch ME
        disp(ME.message)
        disp([getUTC,': Something went wrong during TBD processing  ' tbdFilesToProcess{i,1} ', this data has not been processed'])
    end
end
cd(startDir);
clear modTime directoryList n ind



%% --- Transferr data ---
try
    disp([getUTC ': Starting syncing of to /gfi/projects for norglider web portal']);
    copyfile(fullfile(cfg.DATA_DIR,'active_gliders_surface.json'),cfg.WEB_SERVER_DIR);
    
   plts = load('plots_to_export');
    % Copy these science files
    for i = 1:numel(plts.science_plots)
        this_png = fullfile(SCI_TR_DIR,[plts.science_plots{i} '.png']);
        if exist(this_png,'file')
            copyfile(this_png,fullfile(WEB_DIR,'science'));
        else
            [~,namef, ~] = fileparts(this_png);
            disp(['File does not exist: ' namef])
        end
    end
    
    % Copy these eng files
    for i = 1:numel(plts.flight_plots)
        this_png = fullfile(ENG_TR_DIR,[plts.flight_plots{i} '.png']);
        if exist(this_png,'file')
            copyfile(this_png,fullfile(WEB_DIR,'flight'));
        else
            [~,namef, ~] = fileparts(this_png);
            disp(['File does not exist: ' namef])
        end
    end
    
    % Copy these surface files
    for i = 1:numel(plts.surface_plots)
        this_png = fullfile(SURF_DIR,[plts.surface_plots{i} '.png']);
        if exist(this_png,'file')
            copyfile(this_png,fullfile(WEB_DIR,'surface'));
        else
            [~,namef, ~] = fileparts(this_png);
            disp(['File does not exist: ' namef])
        end
    end
    
    
catch
    disp('Git sync did not work')
end

screen_print('minor',['FINISHED ' mfilename])


