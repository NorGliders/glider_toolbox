%MAIN_GLIDER_DATA_PROCESSING_RT  Run near real time glider processing chain.
% Last update 25.10.22 FE
%
% TODO:
%       - UPDATE KML
%       - standardise plots
%       - update to github
%       - standard position files
%
%  Description:
%    This script develops the full processing chain for real time glider data:
%      - Check for active deployments from deployment information source.
%      - Download new or updated deployment raw data files.
%      - Convert downloaded files to human readable format.
%      - Load data from all files in a single and consistent structure.
%      - Generate standarized product version of raw data (NetCDF level 0).
%      - Preprocess raw data applying simple unit conversions and factory
%        calibrations without modifying their nominal value:
%          -- Select reference sensors for time and space coordinates.
%             Perform unit conversions if necessary.
%          -- Select extra navigation sensors: waypoints, pitch, depth...
%             Perform unit conversions if necessary.
%          -- Select sensors of interest: CTD, oxygen, ocean color...
%             Perform unit conversions and factory calibrations if necessary.
%      - Process preprocessed data to obtain well referenced trajectory data
%        with new derived measurements and corrections:
%          -- Fill missing values of time and space reference sensors.
%          -- Fill missing values of other navigation sensors.
%          -- Identify transect boundaries at waypoint changes.
%          -- Identify cast boundaries from vertical direction changes.
%          -- Apply generic sensor processings: senseor lag correction...
%          -- Process CTD data: pressure filtering, thermal lag correction...
%          -- Derive new measurements: depth, salinity, density...
%      - Generate standarized product version of trajectory data (NetCDF
%        level 1).
%      - Generate descriptive figures from trajectory data.
%      - Interpolate/bin trajectory data to obtain gridded data (vertical
%        instantaneous profiles of already processed data).
%      - Generate standarized product version of gridded data (NetCDF level 2).
%      - Generate descriptive figures from gridded data.
%      - Copy generated data products to its public location, if needed.
%      - Copy generated figures to its public location and generate figure
%        information service file, if needed.
%
%    Deployment information is queried from a data base by GETDEPLOYMENTINFODB.
%    Data base access parameters may be configured in CONFIGDBACCESS.
%    Selected deployments and their metadata fields may be configured in
%    CONFIGRTDEPLOYMENTINFOQUERYDB.
%
%    For each deployment, the messages produced during each processing step are
%    recorded to a log file. This recording is enabled just before the start of
%    the processing of the deployment, and it is turned off when the processing
%    finishes, with the function DIARY.
%
%    New raw data files of the deployment are fetched from remote servers.
%    For Slocum gliders, binary and log files are retrieved by
%    GETDOCKSERVERFILES from each dockserver specified in CONFIGDOCKSERVERS,
%    and stored in the binary and log directories configured in
%    CONFIGRTPATHSLOCAL. For Seaglider gliders, engineering data files and
%    log data files are retrieved by GETBASESTATIONFILES from each basestation
%    specified in CONFIGBASESTATIONS, and stored in the ascii folder specified
%    in CONFIGRTPATHSLOCAL. For SeaExplorer gliders the file retrieval is not
%    implemented yet. The names of the files to download may be restricted in
%    CONFIGRTFILEOPTIONSSLOCUM and CONFIGRTFILEOPTIONSSEAGLIDER.
%
%    For Slocum gliders fetched binary files are converted to text format.
%    The conversion is performed by function XBD2DBA, which is called for each
%    binary file with a renaming pattern to specify the name of the resulting
%    text file, and performs a system call to program 'dbd2asc' by WRC.
%    The path to the 'dbd2asc' program may be configured in CONFIGWRCPROGRAMS.
%    File conversion options may be configured in CONFIGRTFILEOPTIONSSLOCUM,
%    and the directory for converted text files in CONFIGRTPATHSLOCAL.
%
%    Input deployment raw data is loaded from the directory of raw text files
%    with LOADSLOCUMDATA, LOADSEAGLIDERDATA or LOADSEAEXPLORERDATA.
%    Data loading options may be configured in CONFIGRTFILEOPTIONSSLOCUM,
%    CONFIGRTFILEOPTIONSSEAGLIDER, and CONFIGRTFILEOPTIONSSEAEXPLORER.
%
%    Output products, figures and processing logs are generated to local paths.
%    Input and output paths may be configured using expressions built upon
%    deployment field value replacements in CONFIGRTPATHSLOCAL.
%
%    Raw data is preprocessed to apply some simple unit conversions with the
%    function PREPROCESSGLIDERDATA. The preprocessing options and its
%    parameters may be configured in CONFIGDATAPREPROCESSINGSLOCUM,
%    CONFIGDATAPREPROCESSINGSEAGLIDER and CONFIGDATAPREPROCESSINGSEAEXPLORER.
%
%    Preprocessed data is processed with PROCESSGLIDERDATA to obtain properly
%    referenced data with a trajectory data structure. The desired processing
%    actions (interpolations, filterings, corrections and derivations)
%    and its parameters may be configured in CONFIGDATAPROCESSINGSLOCUMG1,
%    CONFIGDATAPROCESSINGSLOCUMG2, CONFIGDATAPROCESSINGSEAGLIDER and
%    CONFIGDATAPROCESSINGSEAEXPLORER.
%
%    Processed data is interpolated/binned with GRIDGLIDERDATA to obtain a data
%    set with the structure of a trajectory of instantaneous vertical profiles
%    sampled at a common set of regular depth levels. The desired gridding
%    parameters may be configured in CONFIGDATAGRIDDING.
%
%    Standard products in NetCDF format are generated from raw data,
%    processed data and gridded data with GENERATEOUTPUTNETCDF.
%    Raw data is stored in NetCDF format as level 0 output product.
%    This file mimics the appearance of the raw data text files, but gathering
%    all useful data in a single place. Hence, the structure of the resulting
%    NetCDF file varies with each type of glider, and may be configured
%    in CONFIGRTOUTPUTNETCDFL0SLOCUM, CONFIGRTOUTPUTNETCDFL0SEAGLIDER and
%    CONFIGRTOUTPUTNETCDFL0SEAEXPLORER. Processed and gridded data sets are
%    stored in NetCDF format as level 1 and level 2 output products
%    respectively. The structure of these files does not depend on the type
%    of glider the data comes from, and may be configured in
%    CONFIGRTOUTPUNETCDFL1 and CONFIGRTOUTPUTNETCDFL2 respectively.
%
%    Figures describing the collected glider data may be generated from
%    processed data and from gridded data. Figures are generated by
%    GENERATEGLIDERFIGURES, and may be configured in CONFIGFIGURES.
%    Available plots are: scatter plots of measurements on vertical transect
%    sections, temperature-salinity diagrams, trajectory and current maps,
%    and profile statistics plots. Other plot functions may be used,
%    provided that their call syntax is compatible with GENERATEGLIDERFIGURES.
%
%    Selected data output products and figures may be copied to a public
%    location for distribution purposes. For figures, a service file describing
%    the available figures and their public location may also be generated.
%    This file is generated by function SAVEJSON with the figure information
%    returned by GENERATEGLIDERFIGURES updated with the new public location.
%    Public products and figures to copy and their locations may be configured
%    in CONFIGRTPATHSPUBLIC.
%
%  See also:
%    CONFIGWRCPROGRAMS
%    CONFIGDOCKSERVERS
%    CONFIGBASESTATIONS
%    CONFIGDBACCESS
%    CONFIGRTDEPLOYMENTINFOQUERYDB
%    CONFIGRTPATHSLOCAL
%    CONFIGRTFILEOPTIONSSLOCUM
%    CONFIGRTFILEOPTIONSSEAGLIDER
%    CONFIGRTFILEOPTIONSSEAEXPLORER
%    CONFIGDATAPREPROCESSINGSLOCUM
%    CONFIGDATAPREPROCESSINGSEAGLIDER
%    CONFIGDATAPREPROCESSINGSEAEXPLORER
%    CONFIGDATAPROCESSINGSLOCUMG1
%    CONFIGDATAPROCESSINGSLOCUMG2
%    CONFIGDATAPROCESSINGSEAGLIDER
%    CONFIGDATAPROCESSINGSEAEXPLORER
%    CONFIGDATAGRIDDING
%    CONFIGRTOUTPUTNETCDFL0SLOCUM
%    CONFIGRTOUTPUTNETCDFL0SEAGLIDER
%    CONFIGRTOUTPUTNETCDFL0SEAEXPLORER
%    CONFIGRTOUTPUTNETCDFL1
%    CONFIGRTOUTPUTNETCDFL2
%    CONFIGFIGURES
%    GETDEPLOYMENTINFODB
%    GETDOCKSERVERFILES
%    GETBASESTATIONFILES
%    LOADSLOCUMDATA
%    PREPROCESSGLIDERDATA
%    PROCESSGLIDERDATA
%    GRIDGLIDERDATA
%    GENERATEOUTPUTNETCDF
%    GENERATEFIGURES
%    DIARY
%    STRFSTRUCT
%    XBD2DBA
%    SAVEJSON
%
%  Notes:
%    This script is based on the previous work by Tomeu Garau. He is the true
%    glider man.
%
%  Authors:
%    Joan Pau Beltran  <joanpau.beltran@socib.cat>

%  Copyright (C) 2013-2016
%  ICTS SOCIB - Servei d'observacio i prediccio costaner de les Illes Balears
%  <http://www.socib.es>
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program.  If not, see <http://www.gnu.org/licenses/>.

%% Debug
debugg = false;
if debugg
    dbstop if error
end


%% Configuration and deployment files
configuration_file   = 'configMainRT.txt';
deployment_file      = 'deploymentRT.txt';

% Required parameters of deployment structure
required_deployment_strparam = {'deployment_name', 'glider_name', ...
    'glider_serial', 'glider_model'};
required_deployment_numparam = {'deployment_id', ...
    'deployment_start', 'deployment_end'};


%% Configure toolbox and configuration file path.
glider_toolbox_dir = configGliderToolboxPath();
glider_toolbox_ver = configGliderToolboxVersion();

fconfig = fullfile(glider_toolbox_dir, 'config', configuration_file);
config = setupConfiguration(glider_toolbox_dir, 'fconfig', fconfig);
deployment_file = fullfile(glider_toolbox_dir, 'config', deployment_file);


%% Configure deployment data and binary paths.
% This is necessary since we changed the configuration setup
config.paths_public.netcdf_l0          = fullfile(config.public_paths.base_dir,config.public_paths.netcdf_l0);
config.paths_public.netcdf_l1          = fullfile(config.public_paths.base_dir,config.public_paths.netcdf_l1);
config.paths_public.netcdf_l2          = fullfile(config.public_paths.base_dir,config.public_paths.netcdf_l2);
config.paths_public.figure_dir         = fullfile(config.public_paths.base_html_dir,config.public_paths.figure_dir);
config.paths_public.figure_url         = fullfile(config.public_paths.base_url,config.public_paths.figure_dir);
config.paths_public.figure_info        = fullfile(config.public_paths.base_html_dir,config.public_paths.figure_info);

config.paths_local.root_dir             = fullfile(config.local_paths.root_dir);
config.paths_local.base_dir             = fullfile(config.local_paths.base_dir);
config.paths_local.active_gliders_json  = fullfile(config.local_paths.active_gliders_json);
config.paths_local.binary_path          = fullfile(config.local_paths.base_dir,config.local_paths.binary_path);
config.paths_local.cache_path           = fullfile(config.local_paths.base_dir,config.local_paths.cache_path);
config.paths_local.log_path             = fullfile(config.local_paths.base_dir,config.local_paths.log_path);
config.paths_local.ascii_path           = fullfile(config.local_paths.base_dir,config.local_paths.ascii_path);
config.paths_local.dat_path             = fullfile(config.local_paths.base_dir,config.local_paths.dat_path);
config.paths_local.figure_path          = fullfile(config.local_paths.base_dir,config.local_paths.figure_path);
config.paths_local.figure_surf_path     = fullfile(config.local_paths.base_dir,config.local_paths.figure_surf_path);
config.paths_local.segment_path         = fullfile(config.local_paths.base_dir,config.local_paths.segment_path);
config.paths_local.netcdf_l0            = fullfile(config.local_paths.base_dir,config.local_paths.netcdf_l0);
config.paths_local.netcdf_l1            = fullfile(config.local_paths.base_dir,config.local_paths.netcdf_l1);
config.paths_local.netcdf_l2            = fullfile(config.local_paths.base_dir,config.local_paths.netcdf_l2);
config.paths_local.processing_log       = fullfile(config.local_paths.root_dir,config.local_paths.processing_log);
config.paths_local.config_record        = fullfile(config.local_paths.root_dir,config.local_paths.config_record);
config.paths_local.processed_xbds_file  = fullfile(config.local_paths.base_dir,config.local_paths.processed_xbds_file);
config.paths_local.processed_logs_file  = fullfile(config.local_paths.base_dir,config.local_paths.processed_logs_file);

config.paths_local.ego_file             = fullfile(config.local_paths.root_dir,config.local_paths.ego_file);
config.paths_local.ego_sensor_ct        = fullfile(config.local_paths.root_dir,config.local_paths.ego_sensor_ct); % TODO! add ${CTD_SN}
config.paths_local.ego_sensor_do        = fullfile(config.local_paths.root_dir,config.local_paths.ego_sensor_do); % edit add ${CTD_SN}
config.paths_local.ego_sensor_eco       = fullfile(config.local_paths.root_dir,config.local_paths.ego_sensor_eco); % edit add ${CTD_SN}

config.wrcprogs.dbd2asc                 = fullfile(config.wrcprogs.base_dir, config.wrcprogs.dbd2asc);
config.wrcprogs.dba_merge               = fullfile(config.wrcprogs.base_dir, config.wrcprogs.dba_merge);
config.wrcprogs.dba_sensor_filter       = fullfile(config.wrcprogs.base_dir, config.wrcprogs.dba_sensor_filter);
config.wrcprogs.dba_time_filter         = fullfile(config.wrcprogs.base_dir, config.wrcprogs.dba_time_filter);
config.wrcprogs.dba2_orig_matlab        = fullfile(config.wrcprogs.base_dir, config.wrcprogs.dba2_orig_matlab);
config.wrcprogs.rename_dbd_files        = fullfile(config.wrcprogs.base_dir, config.wrcprogs.rename_dbd_files);


%% Testing
command = ['echo "main_rt starttime: ' datestr(now) '" >> ' fullfile(config.paths_local.root_dir,'.logs','main_rt.log') ];
[status,result] = system(command);


%% Configure data base deployment information source.
[config.db_query, config.db_fields] = configRTDeploymentInfoQueryDB();

% Get list of deployments to process from database.
% If the active parameter is set and set to 0 then the deployments will be
% gathered from the deployment file under config
user_db_access = 0; % Use 1 for database, and 0 to check deployment json files
deployment_list = '';
if ~isempty(config.db_access) && isfield(config.db_access, 'active')
    user_db_access = config.db_access.active;
end
if user_db_access
    disp('Querying information of glider deployments...');
    deployment_list_2 = getDeploymentInfoDB( ...
        config.db_query, config.db_access.name, ...
        'user', config.db_access.user, 'pass', config.db_access.pass, ...
        'server', config.db_access.server, 'driver', config.db_access.driver, ...
        'fields', config.db_fields);
else
%    disp(['Reading information of glider deployments from ' deployment_file '...']);
    try
        %read_deployment = readConfigFile(deployment_file);
        deployment_list = readConfigJSONDeploymentFiles(config.paths_local.root_dir);  
        %deployment_list = read_deployment.deployment_list;
%         
%         %Check/modify format of deployment_list
%         for i=1:numel(required_deployment_strparam)
%             fieldname = required_deployment_strparam(i);
%             if ~isfield( deployment_list, fieldname{1})
%                 disp(['ERROR: Deployment definition does not contain ' fieldname{1}]);
%                 return;
%             end
%         end
%         for i=1:numel(required_deployment_numparam)
%             fieldname = required_deployment_numparam(i);
%             if ~isfield( deployment_list, fieldname{1})
%                 disp(['ERROR: Deployment definition does not contain ' fieldname{1}]);
%                 return;
%             else
%                 for j=1:numel(deployment_list)
%                     deployment_list(j).(fieldname{1}) = str2num(deployment_list(j).(fieldname{1}));
%                 end
%             end
%         end
     catch exception
        disp(['Error reading deployment file ' deployment_file]);
        disp(getReport(exception, 'extended'));
     end
end

if isempty(deployment_list)
    disp('No active glider deployments available.');
    return
else
    disp(['Active deployments found: ' num2str(height(deployment_list))]);
end

%% Update Active_NorGliders.kml
update_active_norgliders_kml(config.paths_local.root_dir, {deployment_list.deployment_name})


%% Process active deployments.
for deployment_idx = 1:numel(deployment_list)
    %% Set deployment field shortcut variables and initialize other ones.
    % Initialization of big data variables may reduce out of memory problems,
    % provided memory is properly freed and not fragmented.
    deployment = deployment_list(deployment_idx);
    fprintf(1, '\n--------------------------------------------------------------------------------------------------\n')
    fprintf(1, 'Processing deployment %s - %s.......\n', upper(char(deployment.glider_name)), char(deployment.deployment_name));
    fprintf(1, '--------------------------------------------------------------------------------------------------\n')
    processing_log = strfstruct(config.paths_local.processing_log, deployment);
    config_record  = strfstruct(config.paths_local.config_record, deployment);
    local_root_dir = strfstruct(config.paths_local.root_dir, deployment);
    local_base_dir = strfstruct(config.paths_local.base_dir, deployment);
    binary_dir = strfstruct(config.paths_local.binary_path, deployment);
    cache_dir = strfstruct(config.paths_local.cache_path, deployment);
    log_dir = strfstruct(config.paths_local.log_path, deployment);
    ascii_dir = strfstruct(config.paths_local.ascii_path, deployment);
    dat_dir = strfstruct(config.paths_local.dat_path, deployment); % FE
    figure_dir = strfstruct(config.paths_local.figure_path, deployment);
    figure_surf_dir = strfstruct(config.paths_local.figure_surf_path, deployment); % FE
    segment_dir = strfstruct(config.paths_local.segment_path, deployment); % FE
    netcdf_l0_file = strfstruct(config.paths_local.netcdf_l0, deployment);
    netcdf_l1_file = strfstruct(config.paths_local.netcdf_l1, deployment);
    netcdf_l2_file = strfstruct(config.paths_local.netcdf_l2, deployment);
    ego_file = strfstruct(config.paths_local.ego_file, deployment);
    ego_sensor_ct = strfstruct(config.paths_local.ego_file, deployment);  %  TODO
    processed_xbds_file = strfstruct(config.paths_local.processed_xbds_file, deployment); % FE
    processed_logs_file = strfstruct(config.paths_local.processed_logs_file, deployment); % FE
    processed_xbds = {}; % FE
    processed_logs = {}; % FE
    source_files = {};
    meta_raw = struct();
    data_raw = struct();
    meta_preprocessed = struct();
    data_preprocessed = struct();
    meta_processed = struct();
    data_processed = struct();
    meta_gridded = struct();
    data_gridded = struct();
    outputs = struct();
    figures = struct();
    deployment_name  = deployment.deployment_name;
    %deployment_id = deployment.deployment_id;
    deployment_start = datenum(deployment.deployment_start); %%FE changed from str
    deployment_end = deployment.deployment_end;
    glider_name = deployment.glider_name;
    glider_model = deployment.glider_model;
    glider_serial = deployment.glider_serial;
    glider_type = lower(deployment.glider_model); %[lower(deployment.glider_instrument_name) '_' lower(deployment.glider_model)];
    %   if ~isempty(regexpi(glider_model, '.*slocum.*g1.*', 'match', 'once'))
    %     glider_type = 'slocum_g1';
    %   elseif ~isempty(regexpi(glider_model, '.*slocum.*g2.*', 'match', 'once'))
    %     glider_type = 'slocum_g2';
    %   elseif ~isempty(regexpi(glider_model, '.*slocum.*g3.*', 'match', 'once'))
    %     glider_type = 'slocum_g3';
    %   elseif ~isempty(regexpi(glider_model, '.*seaglider.*', 'match', 'once'))
    %     glider_type = 'seaglider';
    %   elseif ~isempty(regexpi(glider_model, '.*seaexplorer.*', 'match', 'once'))
    %       glider_type = 'seaexplorer';
    %   end
    % Options depending on the type of glider:
    switch glider_type
        case 'slocum_g1'
            file_options = config.file_options_slocum;
            preprocessing_options = config.preprocessing_options_slocum;
            processing_options = config.processing_options_slocum_g1;
            netcdf_l0_options = config.output_netcdf_l0_slocum;
        case 'slocum_g2'
            file_options = config.file_options_slocum;
            preprocessing_options = config.preprocessing_options_slocum;
            processing_options = config.processing_options_slocum_g2;
            netcdf_l0_options = config.output_netcdf_l0_slocum;
        case {'slocum_g3','slocum_sg3'}
            glider_type = 'slocum_g3';
            file_options = config.file_options_slocum;
            preprocessing_options = config.preprocessing_options_slocum;
            processing_options = config.processing_options_slocum_g2;
            netcdf_l0_options = config.output_netcdf_l0_slocum;
        case 'seaglider'
            file_options = config.file_options_seaglider;
            preprocessing_options = config.preprocessing_options_seaglider;
            processing_options = config.processing_options_seaglider;
            netcdf_l0_options = config.output_netcdf_l0_seaglider;
        case 'seaexplorer'
            file_options = config.file_options_seaexplorer;
            preprocessing_options = config.preprocessing_options_seaexplorer;
            processing_options = config.processing_options_seaexplorer;
            netcdf_l0_options = config.output_netcdf_l0_seaexplorer;
    end
    if isfield(deployment, 'calibrations')
        preprocessing_options.calibration_parameter_list = deployment.calibrations;
    end
    gridding_options = config.gridding_options;
    netcdf_l1_options = config.output_netcdf_l1;
    netcdf_l2_options = config.output_netcdf_l2;
    figproc_options = config.figures_processed.options;
    figgrid_options = config.figures_gridded.options;
    
    % Create folders - Edit FE
    % This is an ugly hack (the best known way) to check if the directory exists.
    [status, attrout] = fileattrib(local_base_dir);
    if ~status
        [status, message] = mkdir(local_base_dir);
    elseif ~attrout.directory
        status = false;
        message = 'not a directory';
    end
    
    folders = {'ascii', 'binary', 'dat', 'figures', 'figures/surface', 'logs', 'netcdf', 'segments'};
    for i = 1:numel(folders)
        folder_name = fullfile(local_base_dir,folders{i});
        [status, attrout] = fileattrib(folder_name);
        if ~status
            [status, message] = mkdir(folder_name);
        elseif ~attrout.directory
            status = false;
            message = 'not a directory';
        end
    end
    
    
    %% Start deployment processing logging.
    % DIARY will fail if log file base directory does not exist.
    % Create the base directory first, if needed.
    % This is an ugly hack (the best known way) to check if the directory exists.
    [processing_log_dir, ~, ~] = fileparts(processing_log);
    [status, attrout] = fileattrib(processing_log_dir);
    if ~status
        [status, message] = mkdir(processing_log_dir);
    elseif ~attrout.directory
        status = false;
        message = 'not a directory';
    end
    % Enable log only if directory was already there or has been created properly.
    if status
        try
            diary(processing_log);
            diary('on');
        catch exception
            disp(['Error enabling processing log diary ' processing_log ':']);
            disp(getReport(exception, 'extended'));
        end
    else
        disp(['Error creating processing log directory ' processing_log_dir ':']);
        disp(message);
    end
    disp(['Deployment processing start time: ' ...
        datestr(posixtime2utc(posixtime()), 'yyyy-mm-ddTHH:MM:SS+00:00')]);
    
    
    %% Report toolbox version:
    disp(['Toolbox version: ' glider_toolbox_ver]);
    
    
    %% Copy configuration file to data folder
    config_record_dir = fileparts(config_record);
    [status, attrout] = fileattrib(config_record_dir);
    if ~status
        [status, message] = mkdir(config_record_dir);
    elseif ~attrout.directory
        status = false;
        message = 'not a directory';
    end
    if status
        [success, message] = copyfile(fconfig, config_record);
        if success
            disp(['Configuration file succesfully copied' ]);
        else
            disp(['Error copying configuration file to local data ' ...
                config_record ': ' fconfig '.']);
            disp(message);
        end
    else
        disp(['Error creating output directory ' config_record_dir ':']);
        disp(message);
    end
    
    
    %% Load list of processed xbd and logs files or create - FE 21.01.05
    if ~exist(processed_xbds_file, 'file')
        command = ['echo -n > ' processed_xbds_file];
        [status,result] = system(command);
        if ~status
            disp(['Processed xbd''s file succesfully created: ' processed_xbds_file])
        else
            disp('Error creating processed xbd''s file')
            disp(result)
        end
    else
        % Load existing master list of xbd files, any method applied to a
        % segment is noted here. If processed_xbds_file is empty if will fail
        try
            processed_xbds = importProcessedXbdList(processed_xbds_file);
        catch
            disp('Failed to load processed_xbds_file, setting processed_xbds to empty')
        end
    end
    
    if ~exist(processed_logs_file, 'file')
        command = ['echo -n > ' processed_logs_file];
        [status,result] = system(command);
        if ~status
            disp(['Processed log''s file succesfully created: ' processed_logs_file])
        else
            disp('Error creating processed log''s file')
            disp(result)
        end
    else
        % Load existing master list of log files
        % if having trouble with too many columns: processed_logs= removevars(processed_logs,{'Row'})
        try
            processed_logs = importProcessedLogList(processed_logs_file);
        catch
            disp('Failed to load processed_logs_file, setting processed_logs to empty')
            processed_logs = {};
        end
    end
    
    %% Restore permissions back to original
    try
        cmd_str = ['chmod 2775 ' local_base_dir];
        [status, cmd_out] = system(cmd_str);
        fprintf(1, '\nRestore file permissions back to original\n\n')
    catch exception
        fprintf(1, '\nError restoring file permissions\n')
        disp(getReport(exception, 'extended'));
    end
    
    
    %% Report deployment information.
    disp('Deployment information:')
    disp(['  Glider name          : ' glider_name]);
    disp(['  Glider model         : ' strrep(glider_type,'_',' ')]);
    disp(['  Glider serial        : ' num2str(glider_serial)]);
    %disp(['  Deployment identifier: ' num2str(deployment_id)]);
    disp(['  Deployment name      : ' deployment_name]);
    disp(['  Deployment start     : ' datestr(deployment_start)]);
    if isnan(deployment_end)
        disp(['  Deployment end       : ' 'undefined']);
    else
        disp(['  Deployment end       : ' datestr(deployment_end)]);
    end
    
    
    % Download deployment glider files from station(s).
    % Check for new or updated deployment files in every dockserver.
    % Deployment start time must be truncated to days because the date of
    % a binary file is deduced from its name only up to day precission.
    % Deployment end time may be undefined.
    fprintf(1, '\nDownload new deployment data...\n');
    if isnan(deployment_end)
        download_final = posixtime2utc(posixtime());
    else
        download_final = deployment_end;
    end
    switch glider_type
        case {'slocum_g1' 'slocum_g2' 'slocum_g3'}
            % Fetch data from dockserver
            if config.dockservers.active
                new_xbds = cell(size(config.dockservers.server));
                new_logs = cell(size(config.dockservers.server));
                total_xbds = cell(size(config.dockservers.server));
                total_logs = cell(size(config.dockservers.server));
                for dockserver_idx = 1:numel(config.dockservers.server)
                    dockserver = config.dockservers.server(dockserver_idx);
                    try
                        % Transfer via rsync, previously used getDockserverFiles
                        [total_xbds{dockserver_idx}, total_logs{dockserver_idx}, new_xbds{dockserver_idx}, new_logs{dockserver_idx}] = ...
                            rsyncDockserverFiles(dockserver, binary_dir, log_dir, ...
                            'glider', glider_name, ...
                            'xbd', file_options.xbd_name_pattern, ...
                            'log', file_options.log_name_pattern, ...
                            'start', deployment_start, ...
                            'final', download_final,...
                            'remote_base_dir', config.dockservers.remote_base_dir,...
                            'remote_xbd_dir',config.dockservers.remote_xbd_dir,...
                            'remote_log_dir', config.dockservers.remote_log_dir,...
                            'local_base_dir', local_base_dir,...
                            'processed_xbds', processed_xbds,...
                            'processed_logs', processed_logs);
                    catch exception
                        disp(['Error getting dockserver files from ' dockserver.host ':']);
                        disp(getReport(exception, 'extended'));
                    end
                end
            end
            total_xbds = [total_xbds{:}];
            total_logs = [total_logs{:}];
            new_xbds = [new_xbds{:}];
            new_logs = [new_logs{:}];
            % Initialize or append processed_xbds table
            if numel(processed_xbds) == 0
                % Create new table for all binary files found
                processed_xbds = createXbdTable(processed_xbds, total_xbds);
                % Save copy to project dir
                writetable(processed_xbds, processed_xbds_file,'WriteRowNames',true)
            else
                % Append new files to table
                if numel(new_xbds) ~= 0
                    processed_xbds = createXbdTable(processed_xbds, new_xbds);
                end
            end

            % Append new files to table
            if numel(new_logs)  %% SET TRUE TO GENERATE NEW JSON FILE!!!
                processed_logs = updateLogTable(processed_logs, new_logs, glider_name);
                % Save copy to project dir
                writetable(processed_logs, processed_logs_file,'WriteRowNames',true);
                
                % Update active_norgliders.json
                segment_list = struct();
                segments_all = processed_xbds; % processed_xbds(processed_xbds.plot_file==1,:);
                segments = [unique(segments_all.segment(:)) unique(segments_all.segment(:))];
                col_names = processed_logs.Properties.VariableNames;
                segment_struct = struct('plot_list','','because','','mission_name','','vehicle_name','','device_str','','current_time','','GPS_time','','GPS_lat','','GPS_lon','','m_lithium_battery_relative_charge','','m_battery','','c_autoballast_volume','');
                fields = fieldnames(segment_struct);
                for ind = 1:size(segments,1)
                    % Create segment name that we can actually sort by
                    this_seg = segments{ind,1};
                    loc = strfind(this_seg,'-');
                    start_str = this_seg(1:loc(end));
                    end_str = sprintf( '%03s',this_seg(loc(end)+1:end));
                    segments{ind,1} = strrep(this_seg,'-','_');
                    segments{ind,2} = [start_str end_str];
                end
                segments = sortrows(segments,2);

                % Put in order
                for ind = 1:size(segments,1)
                    this_seg = segments{ind,1};
                    content = dir(fullfile(segment_dir,this_seg));
                    if ~isempty(content)
                        %segment_list.(this_seg) = segment_struct;
                        content_name = {content.name}';
                        content_isdir = ~[content.isdir]';
                        plot_list = content_name(content_isdir);
                        for index = 1:numel(fields)
                            segment_list.(this_seg).(fields{index}) = '';
                        end
                        segment_list.(this_seg).plot_list = plot_list;

                        % Get surface data
                        log_for_segment = processed_logs(strcmp(processed_logs.segment_name, strrep(this_seg,'_','-')),:);
                        if height(log_for_segment)
                            if height(log_for_segment) > 1
                                % Select row with the most data
                                log_for_segment = sortrows(log_for_segment,'bytes','descend');
                                log_for_segment = log_for_segment(1,:);
                            end

                            for index = 1:numel(fields)
                                if ismember(fields{index},col_names)
                                    segment_list.(this_seg).(fields{index}) = log_for_segment{:,fields{index}};
                                else
                                    segment_list.(this_seg).(fields{index}) = '';
                                end
                            end
                        end
                    end
                end
                updateActiveGlidersJson(processed_logs, segment_list, config.paths_local.active_gliders_json, ego_file, glider_name);
            end

            fprintf(1, 'Binary data files available: %i. New binary files found: %i\n', numel(total_xbds), numel(new_xbds));
            fprintf(1, 'Surface log files available: %i. New log files found: %i\n', numel(total_logs), numel(new_logs));
        case {'seaglider'}
            new_engs = cell(size(config.basestations));
            new_logs = cell(size(config.basestations));
            for basestation_idx = 1:numel(config.basestations)
                basestation = config.dockservers.server(basestation_idx);
                try
                    [new_engs{basestation_idx}, new_logs{basestation_idx}] = ...
                        getDockserverFiles(basestation, ascii_dir, ascii_dir, ...
                        'glider', glider_serial, ...
                        'eng', file_options.eng_name_pattern, ...
                        'log', file_options.log_name_pattern, ...
                        'start', download_start, ...
                        'final', download_final);
                catch exception
                    disp(['Error getting basestation files from ' basestation.host ':']);
                    disp(getReport(exception, 'extended'));
                end
            end
            new_engs = [new_engs{:}];
            new_logs = [new_logs{:}];
            disp(['Engineering data files downloaded: '  num2str(numel(new_engs)) '.']);
            disp(['Dive log data files downloaded: '  num2str(numel(new_logs)) '.']);
        case {'seaexplorer'}
            warning('glider_toolbox:main_glider_data_processing_dt:NotImplemented', ...
                'Real time file retrieval not implemented for SeaExplorer')
        otherwise
    end
   
    
    %% Convert binary glider files to ascii human readable format. % MAY need edit to check ALL bin files have been decoded rather than just new_files
    % For Seaglider, do nothing but join the lists of new eng and log files.
    % For Slocum, convert each downloaded binary file to ascii format in the
    % ascii directory and store the returned absolute path for later use.
    % Since some conversion may fail use a cell array of string cell arrays and
    % flatten it when finished, leaving only the succesfully created dbas.
    % Give a second try to failing files, because they might have failed due to
    % a missing cache file generated later.
    switch glider_type
        case {'slocum_g1' 'slocum_g2' 'slocum_g3'}
            fprintf(1, '\nConverting binary data files to ascii (.dba, .dat and .m) format\n')
            % Keep track of how many files we convert
            new_files = cell(height(processed_xbds),1);
            new_files_dat = cell(height(processed_xbds),1);
            for conversion_retry = 1:2
                % Find files with no dba
                fprintf(1, 'Attempt %i\n', conversion_retry)
                ind_process = processed_xbds.dba == 0;
                if any(ind_process) % If there are any dba's that need to be created continue
                    fprintf(1, 'Found %i files out of %i that require converting to dba \n', sum(ind_process), numel(ind_process))
                    for xbd_idx = 1:height(processed_xbds)
                        if  ~processed_xbds{xbd_idx,'dba'}
                            xbd_name_ext = char(processed_xbds(xbd_idx,:).Properties.RowNames);
                            xbd_fullfile = fullfile(binary_dir,xbd_name_ext);
                            xbd_info = dir(xbd_fullfile);
                            [~, xbd_name, xbd_ext] = fileparts(xbd_fullfile);
                            dba_name_ext = regexprep(xbd_name_ext, ...
                                file_options.xbd_name_pattern, ...
                                file_options.dba_name_replace);
                            dba_fullfile = fullfile(ascii_dir, dba_name_ext);
                            
                            % Create .dba file
                            try
                                new_files{xbd_idx} = {xbd2dba(xbd_fullfile, dba_fullfile, 'cache', cache_dir, 'cmdname', config.wrcprogs.dbd2asc)};
                                processed_xbds(xbd_name_ext,{'dba_name','dba','filesize'}) = {dba_name_ext,true, xbd_info.bytes};
                            catch exception
                                if conversion_retry == 2
                                    xbd_info = dir(xbd_fullfile);
                                    if contains(exception.message, 'Can''t open cache file')
                                        cac_ind = strfind(exception.message,'.CAC');
                                        cac_file = exception.message(cac_ind-8:cac_ind+3);
                                        fprintf(1, '   %s: Can''t find cache file: %s \n', xbd_info.name, cac_file);
                                    elseif contains(exception.message, 'bad binary cycle tag')
                                        fprintf(1, '   %s: Bad binary cycle tag, removing file from future processing list: %i bytes\n', xbd_info.name, xbd_info.bytes);
                                        processed_xbds(xbd_name_ext,{'dba'}) = {2}; % known error = 2
                                    else
                                        disp(getReport(exception, 'extended'));
                                    end
                                else
                                    fprintf(1, '   %s: catch exception for dba creation \n', xbd_info.name);
                                end
                            end
                            
                            % Make .m and .dat files for EGO processing
                            if processed_xbds{xbd_idx,'dba'}==1
                                try
                                    new_files_dat{xbd_idx} = {dba2matlab(xbd_fullfile, dba_fullfile, dat_dir, 'cache', cache_dir, 'cmdname', config.wrcprogs.dbd2asc, 'cmdname2', config.wrcprogs.dba2_orig_matlab)};
                                    processed_xbds(xbd_name_ext,'dat') = {1};
                                catch exception
                                    if conversion_retry == 2
                                        disp(getReport(exception, 'extended'));
                                    end
                                end
                            end
                        end
                    end
                else
                    fprintf(1, 'No files converted to dba on attempt %i of 2\n', conversion_retry)
                end
            end
            % Save processed_xbds
            writetable(processed_xbds, processed_xbds_file,'WriteRowNames',true)
            new_files = [new_files{:}]';
            new_files_dat = [new_files_dat{:}]';
            fprintf(1, 'Binary data files converted to dba: %i of %i\n', numel(new_files), numel(ind_process))
            fprintf(1, 'Dba data files converted to .dat and .m: %i of %i \n', numel(new_files_dat), numel(ind_process))
        case {'seaglider'}
            new_files = [new_engs{:} new_logs{:}];
        case {'seaexplorer'}
            warning('glider_toolbox:main_glider_data_processing_dt:SeaExplorerFilesRT', ...
                'Faking newly retrieved files with contents of ascii directory');
            
            new_files = dir(ascii_dir);
            new_files = {new_files(~[new_files.isdir]).name};
        otherwise
    end
    
    
    %% Sync .DAT and .M files naco folder for EGO ingest
    if ~isempty(new_files_dat)
        fprintf(1, '\nSyncing .m and .dat files to %s\n',config.public_paths.ftp_imr)
        try
            cmd_str1 = ['rsync -azP ' dat_dir '/*.dat ' config.public_paths.ftp_imr_user '@' config.public_paths.ftp_imr ':slocum/' glider_name '/'];
            [status, cmd_out] = system(cmd_str1);
            cmd_str2 = ['rsync -azP ' dat_dir '/*.m ' config.public_paths.ftp_imr_user '@' config.public_paths.ftp_imr ':slocum/' glider_name '/'];
            [status, cmd_out] = system(cmd_str2);
            cmd_str3 = ['rsync -azP ' local_root_dir '*' glider_name '*.json ' config.public_paths.ftp_imr_user '@' config.public_paths.ftp_imr ':slocum/' glider_name '/json/'];
            [status, cmd_out2] = system(cmd_str3);
        catch exception
            disp('Error syncing files to IMR');
            disp(getReport(exception, 'extended'));
        end
    end
    
    
    %% Load data from ascii deployment glider files if there is new data.
    if ~isempty(new_files)
        disp('Loading raw deployment data from text files...');
        load_start = utc2posixtime(deployment_start);
        load_final = posixtime();
        if ~isnan(deployment_end)
            load_final = utc2posixtime(deployment_end);
        end
        try
            switch glider_type
                case {'slocum_g1', 'slocum_g2', 'slocum_g3'}
                    [meta_raw, data_raw] = ...
                        loadSlocumData(ascii_dir, ...
                        file_options.dba_name_pattern_nav, ...
                        file_options.dba_name_pattern_sci, ...
                        'timenav', file_options.dba_time_sensor_nav, ...
                        'timesci', file_options.dba_time_sensor_sci, ...
                        'sensors', 'all', ... %file_options.dba_sensors, ...
                        'period', [load_start load_final], ...
                        'format', 'struct');
                    source_files = {meta_raw.headers.filename_label};
                    % Update table
                    %do something
                    
                case 'seaglider'
                    [meta_raw, data_raw] = ...
                        loadSeagliderData(ascii_dir, ...
                        file_options.log_name_pattern, ...
                        file_options.eng_name_pattern, ...
                        'columns', file_options.eng_columns, ...
                        'params' , file_options.log_params, ...
                        'period', [load_start load_final], ...
                        'format', 'merged');
                    source_files = meta_raw.sources;
                case {'seaexplorer'}
                    [meta_raw, data_raw] = ...
                        loadSeaExplorerData(ascii_dir, ...
                        file_options.gli_name_pattern, ...
                        file_options.pld_name_pattern, ...
                        'timegli', file_options.gli_time, ...
                        'timepld', file_options.pld_time, ...
                        'format', 'struct');
                    source_files = meta_raw.sources;
                otherwise
                    warning('glider_toolbox:main_glider_data_processing_dt:InvalidGliderType', ...
                        'Unknown glider model: %s.', glider_model);
            end
        catch exception
            disp('Error loading raw data:');
            disp(getReport(exception, 'extended'));
        end
    else
        fprintf(1, '\nNo new deployment data, processing and product generation will be skipped.\n')
    end
    
    
    %% Generate L0 NetCDF file (raw/preprocessed data), if needed and possible.
    if ~isempty(fieldnames(data_raw)) && ~isempty(netcdf_l0_file)
        disp('Generating NetCDF L0 output...');
        try
            switch glider_type
                case {'slocum_g1', 'slocum_g2', 'slocum_g3'}
                    outputs.netcdf_l0 = generateOutputNetCDF( ...
                        netcdf_l0_file, data_raw, meta_raw, deployment, ...
                        netcdf_l0_options.variables, ...
                        netcdf_l0_options.dimensions, ...
                        netcdf_l0_options.attributes, ...
                        'time', {'m_present_time' 'sci_m_present_time'}, ...
                        'position', {'m_gps_lon' 'm_gps_lat'; 'm_lon' 'm_lat'}, ...
                        'position_conversion', @nmea2deg, ...
                        'vertical',            {'m_depth' 'sci_water_pressure'}, ...
                        'vertical_conversion', {[]        @(z)(z * 10)}, ...
                        'vertical_positive',   {'down'} );
                case 'seaglider'
                    outputs.netcdf_l0 = generateOutputNetCDF( ...
                        netcdf_l0_file, data_raw, meta_raw, deployment, ...
                        netcdf_l0_options.variables, ...
                        netcdf_l0_options.dimensions, ...
                        netcdf_l0_options.attributes, ...
                        'time', {'elaps_t'}, ...
                        'time_conversion', @(t)(t + meta_raw.start_secs), ...
                        'position', {'GPSFIX_fixlon' 'GPSFIX_fixlat'}, ...
                        'position_conversion', @nmea2deg, ...
                        'vertical',            {'depth'}, ...
                        'vertical_conversion', {@(z)(z * 10)}, ...
                        'vertical_positive',   {'down'} );
                case {'seaexplorer'}
                    outputs.netcdf_l0 = generateOutputNetCDF( ...
                        netcdf_l0_file, data_raw, meta_raw, deployment, ...
                        netcdf_l0_options.variables, ...
                        netcdf_l0_options.dimensions, ...
                        netcdf_l0_options.attributes, ...
                        'time', {'Timestamp' 'PLD_REALTIMECLOCK'}, ...
                        'position', {'NAV_LONGITUDE' 'NAV_LATITUDE'; 'Lon' 'Lat'}, ...
                        'position_conversion', @nmea2deg, ...
                        'vertical',            {'Depth' 'SBD_PRESSURE'}, ...
                        'vertical_conversion', {[]        @(z)(z * 10)}, ...
                        'vertical_positive',   {'down'} );
            end
            disp(['Output NetCDF L0 (raw data) generated: ' outputs.netcdf_l0 '.']);
        catch exception
            disp(['Error generating NetCDF L0 (raw data) output ' netcdf_l0_file ':']);
            disp(getReport(exception, 'extended'));
        end
    end
    
    
    %% Generate raw segment data figures. % FE
    % Loop through m files and plot individual segments add succesfully plotting segments to 'procecessed_xbds'
    % Find files that havn't been plotted, many files will be too small
    % to require plotting but if a .dat file exists we should attempt
    if ~isempty(new_files)
        ind_process = processed_xbds.dat & ~processed_xbds.plot_file;
        if any(ind_process)
            fprintf(1, '\nGenerating segment figures from %i data files\n',sum(ind_process))
            for ind = 1:numel(ind_process)
                if ind_process(ind)
                    dba_file = processed_xbds{ind,'dba_name'};
                    dba_fullfile = fullfile(local_base_dir,'ascii',dba_file{:});
                    try
                        switch glider_type
                            case 'seaglider'
                                % pass
                            case {'slocum_g1', 'slocum_g2', 'slocum_g3'}
                                success = 0;
                                if contains(dba_file,{'-sbd','-mbd'}) % 'dbd'
                                    [success, num_lines, dos_name, mission_name] = generateFlightSegmentFigures(dba_fullfile, deployment, segment_dir);
                                elseif contains(dba_file,{'-tbd','-nbd','-ebd'})
                                    [success, num_lines, dos_name, mission_name]  = generateScienceSegmentFigures(dba_fullfile, deployment, segment_dir);
                                end
                                if success
                                    processed_xbds(ind,{'plot_file','lines','dos_name','mission_name'}) =  {success, num_lines, dos_name, mission_name};
                                end
                        end
                    catch exception
                        disp('Error generating processed data figures:');
                        disp(getReport(exception, 'extended'));
                    end
                end
            end
            % Save processed_xbds
            writetable(processed_xbds, processed_xbds_file,'WriteRowNames',true)
        end
    end
    
    

    %% Generate raw mission figures. % FE
    if ~isempty(fieldnames(data_raw)) && ~isempty(figure_dir)
        fprintf(1, '\nGenerating mission figures from raw data...\n');
        try
            figures.figproc = generateFlightMissionFigures( ...
                data_raw, figproc_options, ...
                'date', datestr(posixtime2utc(posixtime()), 'yyyy-mm-ddTHH:MM:SS+00:00'), ...
                'dirname', figure_dir);
        catch exception
            disp('Error generating processed data figures:');
            disp(getReport(exception, 'extended'));
        end
    end

    

    
    %% Plot log/surface sensors
    if numel(new_logs)
        [status, attrout] = fileattrib(figure_surf_dir);
        if ~status
            [status, message] = mkdir(figure_surf_dir);
        elseif ~attrout.directory
            status = false;
            message = 'not a directory';
        end
        % Plot surface sensors
        try
            generateSurfaceFigures(processed_logs, glider_name, figure_surf_dir, config.sensor_units_slocum);
        catch ME
            disp(ME)
        end
        
        % Plot battery
        try
            generateBatteryFigures(processed_logs, glider_name, figure_surf_dir, config.sensor_units_slocum, deployment_start);
        catch ME
            disp(ME)
        end

        % Create kml layer based on the active gliders json
        srfStruct_to_kml(processed_logs_file, ego_file);
        % write_niwa_position_feed_txt(cfg);
    end

    
    %% Preprocess raw glider data.
    if ~isempty(fieldnames(data_raw))
        fprintf(1, '\nPreprocessing raw data...\n');
        try
            switch glider_type
                case 'seaglider'
                    seaglider_time_sensor_select = ...
                        strcmp('elaps_t', {preprocessing_options.time_list.time});
                    preprocessing_options.time_list(seaglider_time_sensor_select).conversion = ...
                        @(t)(t +  meta_raw.start_secs);
            end
            [data_preprocessed, meta_preprocessed] = ...
                preprocessGliderData(data_raw, meta_raw, preprocessing_options);
        catch exception
            disp('Error preprocessing glider deployment data:');
            disp(getReport(exception, 'extended'));
        end
    end
    
    
    %% Process preprocessed glider data.
    if ~isempty(fieldnames(data_preprocessed))
        fprintf(1, '\nProcessing glider data...\n');
        try
            [data_processed, meta_processed] = ...
                processGliderData(data_preprocessed, meta_preprocessed, processing_options);
        catch exception
            disp('Error processing glider deployment data:');
            disp(getReport(exception, 'extended'));
        end
    end
    
    
    %% Generate L1 NetCDF file (processed data), if needed and possible.
    if ~isempty(fieldnames(data_processed)) && ~isempty(netcdf_l1_file)
        fprintf(1, '\nGenerating NetCDF L1 output...\n');
        try
            outputs.netcdf_l1 = generateOutputNetCDF( ...
                netcdf_l1_file, data_processed, meta_processed, deployment, ...
                netcdf_l1_options.variables, ...
                netcdf_l1_options.dimensions, ...
                netcdf_l1_options.attributes);
            disp(['Output NetCDF L1 (processed data) generated: ' ...
                outputs.netcdf_l1 '.']);
        catch exception
            disp(['Error generating NetCDF L1 (processed data) output ' ...
                netcdf_l1_file ':']);
            disp(getReport(exception, 'extended'));
        end
    end
    
    
    %% Generate processed data figures.
    if ~isempty(fieldnames(data_processed)) && ~isempty(figure_dir)
        fprintf(1, '\nGenerating figures from processed data...\n');
        try
            figures.figproc = generateGliderFigures( ...
                data_processed, figproc_options, ...
                'date', datestr(posixtime2utc(posixtime()), 'yyyy-mm-ddTHH:MM:SS+00:00'), ...
                'dirname', figure_dir);
        catch exception
            disp('Error generating processed data figures:');
            disp(getReport(exception, 'extended'));
        end
    end
    
    
    %% Grid processed glider data.
    if ~isempty(fieldnames(data_processed))
        fprintf(1, '\nGridding glider data...\n');
        try
            [data_gridded, meta_gridded] = ...
                gridGliderData(data_processed, meta_processed, gridding_options);
        catch exception
            disp('Error gridding glider deployment data:');
            disp(getReport(exception, 'extended'));
        end
    end
    
    
    %% Generate L2 (gridded data) netcdf file, if needed and possible.
    if ~isempty(fieldnames(data_gridded)) && ~isempty(netcdf_l2_file)
        fprintf(1, '\nGenerating NetCDF L2 output...\n');
        try
            outputs.netcdf_l2 = generateOutputNetCDF( ...
                netcdf_l2_file, data_gridded, meta_gridded, deployment, ...
                netcdf_l2_options.variables, ...
                netcdf_l2_options.dimensions, ...
                netcdf_l2_options.attributes);
            disp(['Output NetCDF L2 (gridded data) generated: ' ...
                outputs.netcdf_l2 '.']);
        catch exception
            disp(['Error generating NetCDF L2 (gridded data) output ' ...
                netcdf_l2_file ':']);
            disp(getReport(exception, 'extended'));
        end
    end
    
    
    %% Generate gridded data figures.
    if ~isempty(fieldnames(data_gridded)) && ~isempty(figure_dir)
        fprintf(1, '\nGenerating figures from gridded data...\n');
        try
            figures.figgrid = generateGliderFigures( ...
                data_gridded, figgrid_options, ...
                'date', datestr(posixtime2utc(posixtime()), 'yyyy-mm-ddTHH:MM:SS+00:00'), ...
                'dirname', figure_dir);
        catch exception
            disp('Error generating gridded data figures:');
            disp(getReport(exception, 'extended'));
        end
    end
    
    
    %% Copy selected products to corresponding public location, if needed.
    if ~isempty(fieldnames(outputs))
        fprintf(1, '\nCopying public outputs...\n');
        strloglist = '';
        output_name_list = fieldnames(outputs);
        for output_name_idx = 1:numel(output_name_list)
            output_name = output_name_list{output_name_idx};
            if isfield(config.paths_public, output_name) ...
                    && ~isempty(config.paths_public.(output_name))
                output_local_file = outputs.(output_name);
                output_public_file = ...
                    strfstruct(config.paths_public.(output_name), deployment);
                output_public_dir = fileparts(output_public_file);
                [status, attrout] = fileattrib(output_public_dir);
                if ~status
                    [status, message] = mkdir(output_public_dir);
                elseif ~attrout.directory
                    status = false;
                    message = 'not a directory';
                end
                if status
                    [success, message] = copyfile(output_local_file, output_public_file);
                    if success
                        disp(['Public output ' output_name ' succesfully copied: ' ...
                            output_public_file '.']);
                        if ~isempty(strloglist)
                            strloglist = strcat(strloglist,{', '});
                        end
                        strloglist = strcat(strloglist,output_public_file);
                    else
                        disp(['Error creating public copy of deployment product ' ...
                            output_name ': ' output_public_file '.']);
                        disp(message);
                    end
                else
                    disp(['Error creating public output directory ' ...
                        output_public_dir ':']);
                    disp(message);
                end
            end
        end
        if ~isempty(strloglist)
            strloglist = strcat({'__SCB_LOG_MSG_UPDATED_PUBLIC_FILES__ ['}, strloglist, ']');
            disp(strloglist{1});
        end
    end
    
    
    %% Copy selected figures to its public location, if needed.
    % Copy all generated figures or only the ones in the include list (if any)
    % excluding the ones in the exclude list.
%     if ~isempty(fieldnames(figures)) ...
%             && isfield(config.paths_public, 'figure_dir') ...
%             && ~isempty(config.paths_public.figure_dir)
%         disp('Copying public figures...');
%         public_figure_baseurl = ...
%             strfstruct(config.paths_public.figure_url, deployment);
%         public_figure_dir = ...
%             strfstruct(config.paths_public.figure_dir, deployment);
%         public_figure_include_all = true;
%         public_figure_exclude_none = true;
%         public_figure_include_list = [];
%         public_figure_exclude_list = [];
%         if isfield(config.paths_public, 'figure_include')
%             public_figure_include_all = false;
%             public_figure_include_list = config.paths_public.figure_include;
%         end
%         if isfield(config.paths_public, 'figure_exclude')
%             public_figure_exclude_none = false;
%             public_figure_exclude_list = config.paths_public.figure_exclude;
%         end
%         public_figures = struct();
%         public_figures_local = struct();
%         figure_output_name_list = fieldnames(figures);
%         for figure_output_name_idx = 1:numel(figure_output_name_list)
%             figure_output_name = figure_output_name_list{figure_output_name_idx};
%             figure_output = figures.(figure_output_name);
%             figure_name_list = fieldnames(figure_output);
%             for figure_name_idx = 1:numel(figure_name_list)
%                 figure_name = figure_name_list{figure_name_idx};
%                 if (public_figure_include_all ...
%                         || ismember(figure_name, public_figure_include_list)) ...
%                         && (public_figure_exclude_none ...
%                         || ~ismember(figure_name, public_figure_exclude_list))
%                     if isfield(public_figures_local, figure_name)
%                         disp(['Warning: figure ' figure_name ' appears to be duplicated.']);
%                     else
%                         public_figures_local.(figure_name) = figure_output.(figure_name);
%                     end
%                 end
%             end
%         end
%         public_figure_name_list = fieldnames(public_figures_local);
%         if ~isempty(public_figure_name_list)
%             [status, attrout] = fileattrib(public_figure_dir);
%             if ~status
%                 [status, message] = mkdir(public_figure_dir);
%             elseif ~attrout.directory
%                 status = false;
%                 message = 'not a directory';
%             end
%             if status
%                 for public_figure_name_idx = 1:numel(public_figure_name_list)
%                     public_figure_name = public_figure_name_list{public_figure_name_idx};
%                     figure_local = public_figures_local.(public_figure_name);
%                     figure_public = figure_local;
%                     figure_public.url = ...
%                         [public_figure_baseurl '/' ...
%                         figure_public.filename '.' figure_public.format];
%                     figure_public.dirname = public_figure_dir;
%                     figure_public.fullfile = ...
%                         fullfile(figure_public.dirname, ...
%                         [figure_public.filename '.' figure_public.format]);
%                     [success, message] = ...
%                         copyfile(figure_local.fullfile, figure_public.fullfile);
%                     if success
%                         public_figures.(public_figure_name) = figure_public;
%                         disp(['Public figure ' public_figure_name ' succesfully copied.']);
%                     else
%                         disp(['Error creating public copy of figure ' ...
%                             public_figure_name ': ' figure_public.fullfile '.']);
%                         disp(message);
%                     end
%                 end
%             else
%                 disp(['Error creating public figure directory ' public_figure_dir ':']);
%                 disp(message);
%             end
%         end
%         % Write the figure information to the JSON service file.
%         if isfield(config.paths_public, 'figure_info') ...
%                 && ~isempty(config.paths_public.figure_info)
%             disp('Generating figure information service file...');
%             public_figure_info_file = ...
%                 strfstruct(config.paths_public.figure_info, deployment);
%             try
%                 savejson(public_figures, public_figure_info_file);
%                 disp(['Figure information service file successfully generated: ' ...
%                     public_figure_info_file]);
%             catch exception
%                 disp(['Error creating figure information service file ' ...
%                     public_figure_info_file ':']);
%                 disp(message);
%             end
%         end
%     end
    
    
    %% Restore permissions back to original
    try
        cmd_str = ['chmod 2775 ' local_base_dir];
        [status, cmd_out] = system(cmd_str);
        fprintf(1, '\nRestore file permissions back to original\n')
    catch exception
        fprintf(1, '\nError restoring file permissions\n')
        disp(getReport(exception, 'extended'));
    end
    
    
    %% Summarise state of glider files
    try
        list_ext = processed_xbds{:,'ext'};
        fprintf(1, '\nFile information\n');
        fprintf(1, '  Total number of binary files          : %i \n',height(processed_xbds));
        fprintf(1, '  Number of sbd files                   : %i \n',sum(list_ext=='sbd'));
        fprintf(1, '  Number of mbd files                   : %i \n',sum(list_ext=='mbd'));
        fprintf(1, '  Number of dbd files                   : %i \n',sum(list_ext=='dbd'));
        fprintf(1, '  Number of tbd files                   : %i \n',sum(list_ext=='tbd'));
        fprintf(1, '  Number of nbd files                   : %i \n',sum(list_ext=='nbd'));
        fprintf(1, '  Number of ebd files                   : %i \n',sum(list_ext=='ebd'));
        fprintf(1, '  Number of dba files                   : %i \n',sum(processed_xbds{:,'dba'}==1));
        fprintf(1, '  Number of dat files                   : %i \n',sum(processed_xbds{:,'dat'}==1));
        fprintf(1, '  Number of files that have been plotted: %i \n',sum(processed_xbds{:,'plot_file'}==1));
    end
    
    %% Stop deployment processing logging.
    fprintf(1, '\nDeployment processing end time: %s\n',datestr(posixtime2utc(posixtime()), 'yyyy-mm-ddTHH:MM:SS+00:00'));
    fprintf(1, '--------------------------------------------------------------------------------------------------\n')
    
    diary('off');
    
end
