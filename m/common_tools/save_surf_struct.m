function save_surf_struct(cfg,myStruct)
%-----------------------------------------------------------------------------------------
% [] = save_surf_struct(cfg,myStruct)
%
% Save the latest surface log file from all active gliders to a mat and
% json file named 'active_gliders_surface.mat/json'. active_gliders_surface will  only 
% contain the most recent surfacing info, this script will overwrite existing data from 
% the same glider. The json file is required for web display
%
% Input arguments: cfg - config struct 
%                  myStruct - structure from latest
%
% Outputs: active_gliders_surface.mat
%          active_gliders_surface.json
%
% NIWA Slocum toolbox
%
% History:
% 2016-Jan-20 FE Created
    % Update JSON file - FE 13.08.21
%     load(fullfile(OUT_DIR,[GLIDER,'_srfStruct.mat']));
%     %updateMissionJSON
%     % get last surface struct
%     jsonStruct = srfStruct(end);

%-----------------------------------------------------------------------------------------

%% active_gliders_surface
file = fullfile(cfg.DATA_DIR, 'active_gliders_surface.mat');
jsonfile = fullfile(cfg.DATA_DIR, 'active_gliders_surface.json');

% Save to .mat
if exist(file, 'file')
    % If file exists, load so we can append it or replace
    load(file);
else
    gliders = [];
end

archive_dir = fullfile(cfg.DS_DIR, 'archive');
goto_files = dir([archive_dir '/*goto_l10.ma']);
goto_files = sort({goto_files.name}');
goto = fullfile(archive_dir, goto_files{end});
goto_list = generate_current_waypoints_uib(cfg, goto);

myStructTS = myStruct(end);
myStructTS.Project = cfg.SITE; % HACK www wants site
myStructTS.Mission = cfg.DEPLOY_ID; % HACK www wants mission name
myStructTS.Goto = goto_list;

myStructTS.TS.Time = {myStruct.CurrentTime}';
myStructTS.TS.Position = {myStruct.GPSLocation}';
myStructTS.TS.SegmentName = {myStruct.SegmentName}';

current_waypoint_lat = dm2dd(myStructTS.Sensors.c_wpt_lat(1));
current_waypoint_lon = dm2dd(myStructTS.Sensors.c_wpt_lon(1));
myStructTS.Waypoint = [current_waypoint_lon, current_waypoint_lat];

% Save file
gliders.(cfg.GLIDER) = myStructTS;
% save(file, 'gliders')
% 
% % Save to JSON
% % We need another 'level' for writing to JSON
% % gliders = load(file);
%savejson('gliders',gliders,'FileName',jsonfile);



% addpath(genpath('/Data/gfi/projects/slocum/matlab/common/tools/jsonlab')) 
% List seagliders currently in mission
SN = 560;
vehicle_name = ['sg' num2str(SN)];
seagliders.(vehicle_name).VehicleName = vehicle_name;
seagliders.(vehicle_name).SerialNumber = num2str(SN);
seagliders.(vehicle_name).Project = 'SIOS';
seagliders.(vehicle_name).Mission = 'sg560_SIOS_WSC_Aug2021';
seagliders.(vehicle_name).MissionStart = '03-Aug-2021 00:00:00';

SN = 562;
vehicle_name = ['sg' num2str(SN)];
seagliders.(vehicle_name).VehicleName = vehicle_name;
seagliders.(vehicle_name).SerialNumber = num2str(SN);
seagliders.(vehicle_name).Project = 'Iceland';
seagliders.(vehicle_name).Mission = 'sg562_NorEMSO_iceland_Sep2021';
seagliders.(vehicle_name).MissionStart = '15-Sep-2021 00:00:00';

SN = 564;
vehicle_name = ['sg' num2str(SN)];
seagliders.(vehicle_name).VehicleName = vehicle_name;
seagliders.(vehicle_name).SerialNumber = num2str(SN);
seagliders.(vehicle_name).Project = 'Barents';
seagliders.(vehicle_name).Mission = 'sg564_LEGACY_barents_Nov2021';
seagliders.(vehicle_name).MissionStart = '11-Nov-2021 13:32:00';


% Seaglider path
data_path = 'H:\gliderbak';
sg_all = fieldnames(seagliders);

% JSON file
%summary_path = '/Data/gfi/projects/slocum/data/real_time'; 
% summary_path = 'G:\data\real_time';
% summary_file = 'active_gliders_surface_temp.json';
% summary = fullfile(summary_path, summary_file);
% existing_json = loadjson(summary);

for ind = 1:numel(sg_all)
    sg = sg_all{ind};
    sn = seagliders.(sg).SerialNumber;
    pa = fullfile(data_path,sg);
    thisglider = seagliders.(sg);
    
    thisglider.Waypoint = '';
    thisglider.Goto = '';
    thisglider.TS = '';

    % NC files
    files = dir(fullfile(pa,['p' sn '*.nc'])); % list of all files in directory
    files = char(files.name); % list of all file names

    d = struct();
    %lon = ones(size(files,1),1)*NaN;
    %lat = ones(size(files,1),1)*NaN;
    ll = cell(size(files,1),1);
    time = cell(size(files,1),1);
    dive = cell(size(files,1),1);
    
    % Extract pos/time
    for ind2 = 1:size(files,1)
        disp(['Reading file: ' files(ind2,:)])
        filenc = fullfile(pa,files(ind2,:));
        %lon(ind2) = nanmean(ncread(filenc,'log_gps_lon'));
        ll{ind2} = [nanmean(ncread(filenc,'log_gps_lat')), nanmean(ncread(filenc,'log_gps_lon'))];
        %lat(ind2)  = nanmean(ncread(filenc,'log_gps_lat')); 
        time{ind2} = datestr(ut2mt(nanmean(ncread(filenc,'log_gps_time')))); 
        dive{ind2} = num2str(ncread(filenc,'log_DIVE'));
        clear filenc
    end
    
    % Save this structure to summary_json
    thisglider.TS.Time = time;
    thisglider.TS.Position =ll;
    thisglider.TS.SegmentName = dive;
    
    % Create or overwrite glider
    %existing_json.gliders.(sg) = thisglider.(sg);
    gliders.(sg) = thisglider;
    clear thisglider
end


savejson('gliders',gliders,'FileName',jsonfile);
save(file, 'gliders')




























%% SECTION TITLE
% DESCRIPTIVE TEXT


% %% 'glider'.json
% missionFile = fullfile(cfg.DATA_DIR,[cfg.GLIDER '_segments.mat']);
% 
% % Save to .mat
% if exist(file,'missionFile')
%     load(missionFile);
% end
% 
% segment.()

