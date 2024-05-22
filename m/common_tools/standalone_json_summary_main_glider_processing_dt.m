% JSON_SUMMARY_MAIN_GLIDER_DATA_PROCESSING_DT
% Based on:
% MAIN_GLIDER_DATA_PROCESSING_DT  Run delayed time glider processing chain.
%


%% Configuration and deployment file
configuration_file = 'configMainDT.txt';
deployment_file    = 'deploymentDT.txt';

% required parameters of deployment structure --put more useful stuff in here
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
config.paths_local.binary_path          = fullfile(config.local_paths.base_dir,config.local_paths.binary_path);
config.paths_local.cache_path           = fullfile(config.local_paths.base_dir,config.local_paths.cache_path);
config.paths_local.log_path             = fullfile(config.local_paths.base_dir,config.local_paths.log_path);
config.paths_local.ascii_path           = fullfile(config.local_paths.base_dir,config.local_paths.ascii_path);
config.paths_local.figure_path          = fullfile(config.local_paths.base_dir,config.local_paths.figure_path);
config.paths_local.netcdf_l0            = fullfile(config.local_paths.base_dir,config.local_paths.netcdf_l0);
config.paths_local.netcdf_l1            = fullfile(config.local_paths.base_dir,config.local_paths.netcdf_l1);
config.paths_local.netcdf_l2            = fullfile(config.local_paths.base_dir,config.local_paths.netcdf_l2);
config.paths_local.processing_log       = fullfile(config.local_paths.base_dir,config.local_paths.processing_log);
config.paths_local.deployment_summary   = fullfile(config.local_paths.base_dir,config.local_paths.deployment_summary);
config.paths_local.all_deployments_summary = fullfile(config.local_paths.all_deployments_summary);

config.paths_local.ego_file             = fullfile(config.local_paths.base_dir,config.local_paths.ego_file);
config.paths_local.ego_sensor_ct        = fullfile(config.local_paths.base_dir,config.local_paths.ego_sensor_ct); % TODO! add ${CTD_SN}
config.paths_local.ego_sensor_do        = fullfile(config.local_paths.base_dir,config.local_paths.ego_sensor_do); % edit add ${CTD_SN}
config.paths_local.ego_sensor_eco       = fullfile(config.local_paths.base_dir,config.local_paths.ego_sensor_eco); % edit add ${CTD_SN}

config.wrcprogs.dbd2asc                 = fullfile(config.wrcprogs.base_dir, config.wrcprogs.dbd2asc);
config.wrcprogs.dba_merge               = fullfile(config.wrcprogs.base_dir, config.wrcprogs.dba_merge);
config.wrcprogs.dba_sensor_filter       = fullfile(config.wrcprogs.base_dir, config.wrcprogs.dba_sensor_filter);
config.wrcprogs.dba_time_filter         = fullfile(config.wrcprogs.base_dir, config.wrcprogs.dba_time_filter);
config.wrcprogs.dba2_orig_matlab        = fullfile(config.wrcprogs.base_dir, config.wrcprogs.dba2_orig_matlab);
config.wrcprogs.rename_dbd_files        = fullfile(config.wrcprogs.base_dir, config.wrcprogs.rename_dbd_files);



%% Configure data base deployment information source.
if ~isfield(config.db_access, 'deployment_ids')
    error('glider_toolbox:main_glider_dataprocessing_dt:MissingConfiguration',...
        'Delayed mode requires deployment ids');
end
[config.db_query, config.db_fields] = configDTDeploymentInfoQueryDB('deployment_ids', config.db_access.deployment_ids);


%% Get list of deployments to process from database.
% If the active parameter is set and set to 0 then the deployments will be
% gathered from the deployment file under config
deployment_list = '';
if ~isempty(config.db_access) && isfield(config.db_access, 'active')
    user_db_access = config.db_access.active;
end
disp('Retrieving glider deployments...');
if user_db_access
    disp(['Querying database: ' config.db_access.server '...']);
    deployment_list = getDeploymentInfoDB( ...
        config.db_query, config.db_access.name, ...
        'user', config.db_access.user, 'pass', config.db_access.pass, ...
        'server', config.db_access.server, 'driver', config.db_access.driver, ...
        'fields', config.db_fields);
else
    %         disp(['Reading from file: ' deployment_file '...']);
    %         try
    %             read_deployment = readConfigFile(deployment_file);
    %             deployment_list = read_deployment.deployment_list;
    %
    %             % Check/modify format of deployment_list
    %             for i=1:numel(required_deploy ment_strparam)
    %                 fieldname = required_deployment_strparam(i);
    %                 if ~isfield( deployment_list, fieldname{1})
    %                     disp(['ERROR: Deployment definition does not contain ' fieldname{1}]);
    %                     return;
    %                 end
    %             end
    %             for i=1:numel(required_deployment_numparam)
    %                 fieldname = required_deployment_numparam(i);
    %                 if ~isfield( deployment_list, fieldname{1})
    %                     disp(['ERROR: Deployment definition does not contain ' fieldname{1}]);
    %                     return;
    %                 else
    %                     for j=1:numel(deployment_list)
    %                         deployment_list(j).(fieldname{1}) = str2num(deployment_list(j).(fieldname{1}));
    %                     end
    %                 end
    %             end
    %         catch exception
    %             disp(['Error reading deployment file ' deployment_file]);
    %             disp(getReport(exception, 'extended'));
    %         end
    
    disp(['Reading from xlxs spreadsheet: ' config.db_access.server '...']);
    % TODO: ENABLE MULtiselect
    [deployment_list, deployment_table] = getDeploymentInfoXLS(config.db_access.server);
    %         if first_run
    %             deployment_list.deployment_start = NaN;
    %             deployment_list.deployment_end = NaN;
    %         end
end

if isempty(deployment_list)
    disp('Selected glider deployments are not available.');
    return
else
    disp(['Selected deployments found: ' num2str(numel(deployment_list)) '.']);
end

% If seaglider just create kml
if contains(deployment_table.GLIDERPLATFORM,'seaglider') 
    disp('not develpoed yet')
    dm_to_kml(summary, deployment_summary) 
    return
end
    

%% Process active deployments.
for deployment_idx = 1:numel(deployment_list)
    %% Set deployment field shortcut variables and initialize other ones.
    % Initialization of big data variables may reduce out of memory problems,
    % provided memory is properly freed and not fragmented.
    disp(['Processing deployment ' num2str(deployment_idx) '...']);
    deployment = deployment_list(deployment_idx);
    processing_log = strfstruct(config.paths_local.processing_log, deployment);
    deployment_summary  = strfstruct(config.paths_local.deployment_summary, deployment);
    all_deployments_summary = fullfile(config.local_paths.all_deployments_summary);
    binary_dir = strfstruct(config.paths_local.binary_path, deployment);
    cache_dir = strfstruct(config.paths_local.cache_path, deployment);
    log_dir = strfstruct(config.paths_local.log_path, deployment);
    ascii_dir = strfstruct(config.paths_local.ascii_path, deployment);
    figure_dir = strfstruct(config.paths_local.figure_path, deployment);
    netcdf_l0_file = strfstruct(config.paths_local.netcdf_l0, deployment);
    netcdf_l1_file = strfstruct(config.paths_local.netcdf_l1, deployment);
    netcdf_l2_file = strfstruct(config.paths_local.netcdf_l2, deployment);
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
    deployment_id = deployment.deployment_id;
    deployment_start = deployment.deployment_start;
    deployment_end = deployment.deployment_end;
    glider_name = deployment.glider_name;
    glider_model = deployment.glider_model;
    glider_serial = deployment.glider_serial;
    glider_type = '';
    if ~isempty(regexpi(glider_model, '.*slocum.*g1.*', 'match', 'once'))
        glider_type = 'slocum_g1';
    elseif ~isempty(regexpi(glider_model, '.*slocum.*g2.*', 'match', 'once'))
        glider_type = 'slocum_g2';
    elseif ~isempty(regexpi(glider_model, '.*slocum.*g3.*', 'match', 'once'))
        glider_type = 'slocum_g3';
    elseif ~isempty(regexpi(glider_model, '.*seaglider.*', 'match', 'once'))
        glider_type = 'seaglider';
    elseif ~isempty(regexpi(glider_model, '.*seaexplorer.*', 'match', 'once'))
        glider_type = 'seaexplorer';
    end
    % Options depending on the type of glider:
    % TO DO ADD RENAME AND UNCOMPRESS HERE!!!
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
        case 'slocum_g3'
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
    
    
    %% Report toolbox version:
    disp(['Toolbox version: ' glider_toolbox_ver]);
    
    
    %% Report deployment information.
    disp('Deployment information:')
    disp(['  Glider name           : ' glider_name]);
    disp(['  Glider model          : ' glider_model]);
    disp(['  Glider serial         : ' num2str(glider_serial)]);
    disp(['  Deployment identifier : ' num2str(deployment_id)]);
    disp(['  Deployment name       : ' deployment_name]);
    if isnan(deployment_start)
        disp(['  Deployment start      : ' 'undefined']);
    else
        disp(['  Deployment start      : ' datestr(deployment_start)]);
    end
    if isnan(deployment_end)
        disp(['  Deployment end        : ' 'undefined']);
    else
        disp(['  Deployment end        : ' datestr(deployment_end)]);
    end
    
    
    
    %% Load data from ascii deployment glider files.
    disp('Loading raw deployment data from text files...');
    load_start = utc2posixtime(deployment_start);
    load_final = posixtime();
    if ~isnan(deployment_end)
        load_final = utc2posixtime(deployment_end);
    end
    try
        switch glider_type
            case {'slocum_g1' 'slocum_g2' 'slocum_g3'}
                [meta_raw, data_raw] = ...
                    loadSlocumData(ascii_dir, ...
                    file_options.dba_name_pattern_nav, ...
                    file_options.dba_name_pattern_sci, ...
                    'timenav', file_options.dba_time_sensor_nav, ...
                    'timesci', file_options.dba_time_sensor_sci, ...
                    'sensors', file_options.dba_sensors, ...
                    'period', [load_start load_final], ...
                    'format', 'struct');
                source_files = {meta_raw.headers.filename_label};
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
     
    
    %% Preprocess raw glider data.
    if ~isempty(fieldnames(data_raw))
        disp('Preprocessing raw data...');
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
        disp('Processing glider data...');
        try
            [data_processed, meta_processed] = ...
                processGliderData(data_preprocessed, meta_preprocessed, processing_options);
        catch exception
            disp('Error processing glider deployment data:');
            disp(getReport(exception, 'extended'));
        end
    end
end


%% Deployment Summary
json_summary_main_glider_processing_dt(deployment_table, data_processed, figure_dir, deployment_summary, all_deployments_summary) 


%% Stop deployment processing logging.
disp(['Deployment processing end time: ' ...
    datestr(posixtime2utc(posixtime()), 'yyyy-mm-ddTHH:MM:SS+00:00')]);


