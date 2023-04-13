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
%             for i=1:numel(required_deployment_strparam)
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


  %% Make plots to find start and stop times
  if 0 %first_run
      % Find the index of the CTD pressure for the first and last dives to a certain depth
      start_depth_limit = 199;
      end_depth_limit   = 99;
      first_good_CTD    = find(data_processed.pressure>start_depth_limit,1);
      last_good_CTD     = find(data_processed.pressure>end_depth_limit,1, 'last');
      
      % Get the start index of the first profile for first_good_CTD
      start_index = find(data_processed.profile_index == data_processed.profile_index(first_good_CTD),1);
      end_index = find(data_processed.profile_index == data_processed.profile_index(last_good_CTD),1,'last'); % should be last
      disp(['Suggested first timestamp: ' datestr(ut2mt(data_processed.time(start_index)),'yyyy.mm.dd HH:MM:SS')]);
      disp(['Suggested last timestamp: ' datestr(ut2mt(data_processed.time(end_index)),'yyyy.mm.dd HH:MM:SS')]);
      
      % Use these to plot whole profile
      start_index_next = find(data_processed.profile_index == data_processed.profile_index(first_good_CTD)+1.5,1);
      end_index_startof = find(data_processed.profile_index == data_processed.profile_index(last_good_CTD),1);

      % Plot to visually confirm - there may have been issues during deployment testing
      fh = figure('WindowState', 'maximized'); ah1 = axes('ydir','rev');
      plot(fh,datetime(ut2mt(data_processed.time),'ConvertFrom','datenum'),data_processed.pressure,'.');
      hold on
      
      % Start
      plot(fh,datetime(ut2mt(data_processed.time(1:start_index_next)),'ConvertFrom','datenum'),data_processed.pressure(1:start_index_next),'r.');
      plot(fh,datetime(ut2mt(data_processed.time(start_index)),'ConvertFrom','datenum'),0,'o','MarkerEdgeColor','k','MarkerFaceColor','g','MarkerSize',10)

      % End
      plot(fh,datetime(ut2mt(data_processed.time(end_index_startof:end_index)),'ConvertFrom','datenum'),data_processed.pressure(end_index_startof:end_index),'r.');
      plot(fh,datetime(ut2mt(data_processed.time(end_index)),'ConvertFrom','datenum'),0,'o','MarkerEdgeColor','k','MarkerFaceColor','y','MarkerSize',10)
      
      legend('All CTD pressure data found in folder',...
          ['first ' num2str(start_index_next) ' timestamps'],... 
      ['suggested start time: ' datestr(ut2mt(data_processed.time(start_index)),'yyyy.mm.dd HH:MM:SS')],...
      ['last ' num2str(length(data_processed.time)-end_index) ' timestamps'],...
      ['suggested end time: ' datestr(ut2mt(data_processed.time(end_index)),'yyyy.mm.dd HH:MM:SS')],...
          'Location','southwest')
      title('Identify the start and end of deployment timestamps')
      ylabel('Depth from CTD (m)')
      if ~exist(figure_dir,'dir')
          mkdir(figure_dir)
      end
      saveas(fh,fullfile(figure_dir,'timestamps_figure.fig'))
  end
  
  
  %% Deployment Summary
  % Put all fields from deployment database in here
  id = ['g' num2str(deployment_table.MISSIONNUMBER)];
  deployment_fields = fieldnames(deployment_table);
  summary.data_characteristics.title = [num2str(deployment_table.MISSIONNUMBER), '-', deployment_table.INTERNALMISSIONID];
  for i = 1:numel(deployment_fields)
      summary.deployment_characteristics.(deployment_fields{i}) = deployment_table.(deployment_fields{i});
  end
  
  summary.data_characteristics.first_time_stamp = datestr(ut2mt(data_processed.time(1)),'yyyy.mm.dd HH:MM:SS');
  summary.data_characteristics.last_time_stamp = datestr(ut2mt(data_processed.time(end)),'yyyy.mm.dd HH:MM:SS');
  summary.data_characteristics.duration_days = sprintf('%.1f',ut2mt(data_processed.time(end))-ut2mt(data_processed.time(1)));
  summary.data_characteristics.dives =  floor(data_processed.profile_index(end)/2);
  summary.data_characteristics.distance = sprintf('%.0f',max(data_processed.distance_over_ground));
  summary.data_characteristics.longitude_start = data_processed.longitude(find(~isnan(data_processed.longitude),1));
  summary.data_characteristics.longitude_end = data_processed.longitude(find(~isnan(data_processed.longitude),1,'last'));
  summary.data_characteristics.latitude_start = data_processed.latitude(find(~isnan(data_processed.latitude),1));
  summary.data_characteristics.latitude_end = data_processed.latitude(find(~isnan(data_processed.latitude),1,'last'));
  summary.data_characteristics.longitude_min = min(data_processed.longitude);
  summary.data_characteristics.longitude_max = max(data_processed.longitude);
  summary.data_characteristics.latitude_min = min(data_processed.latitude);
  summary.data_characteristics.latitude_max = max(data_processed.latitude);
  summary.data_characteristics.depth_min = sprintf('%.f',min(data_processed.depth));
  summary.data_characteristics.depth_max = sprintf('%.f',max(data_processed.depth));
  summary.data_characteristics.temperature_min = sprintf('%.2f',min(data_processed.temperature));
  summary.data_characteristics.temperature_max = sprintf('%.2f',max(data_processed.temperature));
  summary.data_characteristics.salinity_min = sprintf('%.2f',min(data_processed.salinity));
  summary.data_characteristics.salinity_max = sprintf('%.2f',max(data_processed.salinity));
  summary.data_characteristics.density_min = sprintf('%.2f',min(data_processed.density));
  summary.data_characteristics.density_max = sprintf('%.2f',max(data_processed.density));
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Tracks
  % DAC time stamp and estimate on L1 is at one surfacing time and is an estimate (i.e. depth and time average) from since last surfacing.  It is NOT interpolated to the time between two surfacings.
  % And if we have turns at 2 m depth or so (no surfacing) for multiple yos, we can go with no DAC for many hours...
  % In the summary files produce the tracks as time/lon/lat/DACu/DACv interpolated to the middle time between two surfacings
  
  % Plot pressure data to get an idea of segment configurations i.e no yo's
  fh = figure('WindowState', 'maximized'); ah1 = axes;
  plot(fh,datetime(ut2mt(data_processed.time),'ConvertFrom','datenum'),data_processed.pressure,'.');
  set(ah1,'ydir','rev');
  hold on
  
  % Find points where glider is on surface or just above 0.5m
  at_surface = find(data_processed.pressure < 0.5);
  plot(fh,datetime(ut2mt(data_processed.time(at_surface)),'ConvertFrom','datenum'),data_processed.pressure(at_surface),'or');
  
  % Find the first point on the surface for each profile_index. A glider
  % wont necessarily surface after every profile
  unique_profiles = unique(data_processed.profile_index);
  index_of_start_segment = zeros(size(unique_profiles));
  index_of_start_segment_profiles = zeros(size(unique_profiles));
  lineno = 0;
  for ind = 1:numel(at_surface)
      this_pro_index = data_processed.profile_index(at_surface(ind));
      if ~ismember(this_pro_index, index_of_start_segment_profiles) 
          if (floor(this_pro_index) - this_pro_index) ~= 0
              lineno = lineno + 1;
              index_of_start_segment_profiles(lineno) = this_pro_index;
              index_of_start_segment(lineno) = at_surface(ind);
              disp(['Surfacing number ' num2str(ind) ': profile number: ' num2str(this_pro_index)])
          end
      end
  end
  index_of_start_segment(index_of_start_segment == 0) = [];
  index_of_start_segment_profiles(index_of_start_segment_profiles == 0) = [];
  
  % Plot this as a reference
  plot(fh,datetime(ut2mt(data_processed.time(index_of_start_segment)),'ConvertFrom','datenum'),data_processed.pressure(index_of_start_segment),'.g');

  % Create a new array that assign a segment number to all indexes
  
  
  % Check these values sense  
  % datestr(ut2mt(data_processed.time(index_of_start_segment(3):index_of_start_segment(3)+5)))
  % data_processed.profile_index(index_of_start_segment(3):index_of_start_segment(3)+5)
    
  % Get midpoint of segment: time between tn ad tn+1, mark on plot
  startpoints = ut2mt(data_processed.time(index_of_start_segment)); 
  profile_index_of_startpoints = data_processed.profile_index(index_of_start_segment); 
  diff_midpoints = diff(startpoints);
  midpoint_of_segments = startpoints(1:end-1)+(diff_midpoints)/2;
    
  plot(fh,datetime(midpoint_of_segments,'ConvertFrom','datenum'),zeros(size(diff_midpoints)),'y^','MarkerFaceColor','y');
  
  % get timestamp, interpolated lon and lat and ACTUAL DACu/DACv from
  tracks.time = midpoint_of_segments;
  
  index_DACu = find(~isnan(data_processed.water_velocity_eastward));
  
  disp(['There are ' num2str(numel(index_DACu)) ' DACs and ' num2str(numel(midpoint_of_segments)) ' segment midpoints' ])
  disp('find unneeded points')
  
  
 figure; plot(datetime(ut2mt(data_processed.time),'ConvertFrom','datenum'), data_processed.water_velocity_eastward,'k^','MarkerFaceColor','c');
 hold on
 plot(datetime(ut2mt(data_processed.time),'ConvertFrom','datenum'), data_processed.water_velocity_northward,'ko','MarkerFaceColor','y');

  % check for double ups for a profile:
  doubled_DAC = find(diff(data_processed.profile_index(index_DACu))==0);
%  data_processed.profile_index(index_DACu(1:3))
%  data_processed.water_velocity_northward(index_DACu(58:59))
%  datetime(ut2mt(data_processed.time(index_DACu(1:3))),'ConvertFrom','datenum')
  
  % Plot time of all DAC
  plot(fh,datetime(ut2mt(data_processed.time(index_DACu)),'ConvertFrom','datenum'),zeros(size(index_DACu))-0.05,'k^','MarkerFaceColor','c');
  
  data_processed.profile_index(doubled_DAC)
  
  disp(['Display the ' num2str(numel(doubled_DAC)) ' values when we have multiple DACs for the same profile'])
  if ~isempty(doubled_DAC)
      for ind = 1:numel(doubled_DAC)
          loc = doubled_DAC(ind);
          %plot(fh,datetime(ut2mt(data_processed.time(index_DACu(loc))),'ConvertFrom','datenum'),[0],'ko','MarkerFaceColor','k');     
          if ind == 1
              n = loc -1;
              disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(n)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(n))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(n))) '   loc (before first loc):' num2str(n)])
          end
          disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(loc)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(loc))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(loc))) '   loc:' num2str(loc)])
          if ind == numel(doubled_DAC)
              n = loc+1;
              disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(n)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(n))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(n))) '   loc (after last loc, currently used value):' num2str(n)])
              n = loc+2;
              disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(n)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(n))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(n))) '   loc (after last loc):' num2str(n)])
          end
          %disp(data_processed.profile_index(index_DACu(loc-2:loc+2)))
          %disp(datestr(ut2mt(data_processed.time(index_DACu(loc-2:loc+2)))))
          %disp('loc is')
          %disp(loc)
      end
      % delete the first double
      %index_DACu(doubled_DAC) = [];
  end
  %legend('pressure', 'points above 0.5m','start of segment','sement mid-points','timstamps of DAC raw','removed DACs')
  
  
  % For the doubled_DAC check if any share the same index
  if ~isempty(doubled_DAC)
      get_unique_profile = unique(data_processed.profile_index(index_DACu(doubled_DAC)));
      for ind = 1:numel(get_unique_profile)
          data_processed.profile_index(index_DACu(doubled_DAC)) == get_unique_profile(ind)
      
      unique_profiles = unique(get_profile)
      [C,IA,IC] = unique(get_profile)
      for ind = 1:numel(doubled_DAC)
          loc = doubled_DAC(ind);
          %plot(fh,datetime(ut2mt(data_processed.time(index_DACu(loc))),'ConvertFrom','datenum'),[0],'ko','MarkerFaceColor','k');     
          if ind == 1
              n = loc -1;
              disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(n)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(n))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(n))) '   loc (before first loc):' num2str(n)])
          end
          disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(loc)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(loc))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(loc))) '   loc:' num2str(loc)])
          if ind == numel(doubled_DAC)
              n = loc+1;
              disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(n)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(n))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(n))) '   loc (after last loc, currently used value):' num2str(n)])
              n = loc+2;
              disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(n)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(n))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(n))) '   loc (after last loc):' num2str(n)])
          end

      end

  end
  
  profile_index_of_DAC = data_processed.profile_index(index_DACu);
  tracks.DACu = zeros(size(midpoint_of_segments))*nan;
  tracks.DACv = zeros(size(midpoint_of_segments))*nan;
  for ind = 1:numel(midpoint_of_segments)
      %disp(num2str(midpoint_of_segments(ind)))
      loc = find(ut2mt(data_processed.time(index_DACu)) > midpoint_of_segments(ind),1,'first');
      tracks.DACu(ind) = data_processed.water_velocity_eastward(index_DACu(loc));
      tracks.DACv(ind) = data_processed.water_velocity_northward(index_DACu(loc));
  end
  
  % Lat and long, interpolate to the time
  % Vq = interp1(X,V,Xq)
  tracks.lon = interp1(ut2mt(data_processed.time), data_processed.longitude, tracks.time,'nearest');
  tracks.lat = interp1(ut2mt(data_processed.time), data_processed.latitude, tracks.time,'nearest');
  
  summary.tracks = tracks;
  summary.tracks.time = datestr((summary.tracks.time),'yyyy-mm-dd HH:MM:ss');
  
  re_json_code = jsonencode(summary);
  fid = fopen(deployment_summary,'wt');
  fprintf(fid,'%s',re_json_code);
  fclose(fid);
  
  % Save to master json file
  % If files does not exist create empty structure
  if exist(all_deployments_summary,'file')
      json_code = fileread(all_deployments_summary);
      json_struct = jsondecode(json_code);
  end
  json_struct.deployments.(id) = summary;
  
  % Sort them
  fields = sort(fieldnames(json_struct.deployments));
  
  for ind = 1:numel(fields)
    json_sorted_struct.deployments.(fields{ind}) = json_struct.deployments.(fields{ind});
  end
  
  all_json_code = jsonencode(json_sorted_struct);
  fid = fopen(all_deployments_summary,'wt');
  fprintf(fid,'%s',all_json_code);
  fclose(fid);

  
  %% Stop deployment processing logging.
  disp(['Deployment processing end time: ' ...
        datestr(posixtime2utc(posixtime()), 'yyyy-mm-ddTHH:MM:SS+00:00')]);

end
