function update_all_norgliders_kml()
%--------------------------------------------------------------------------
% update_archive_norgliders_kml()
%
% Links to the kml files from all norgliders deployments 
%
% Outputs:
% updated kmz file
%
% History:
% -2014       ANFOG
%--------------------------------------------------------------------------

%% Configuration variables
local_paths.root_dir            = '/Data/gfi/projects';
local_paths.slocum_dir          = sprintf('%s/%s/data/delayed',local_paths.root_dir,'slocum');
local_paths.seaglider_dir       = sprintf('%s/%s/data/delayed',local_paths.root_dir,'naco');
local_paths.all_gliders_json    = sprintf('%s/slocum/data/delayed/%s',local_paths.root_dir,'all_norgliders.json');
local_paths.all_gliders_kml     = sprintf('%s/slocum/data/delayed/%s',local_paths.root_dir,'all_norgliders.kml');
local_paths.norgliders_spreadsheet = sprintf('%s/naco/gliderdeployments/%s',local_paths.root_dir,'Norwegian_Missions.xlsx');
local_paths.weburl              = 'https://norgliders.gfi.uib.no'; 

server                          = 'naco';
local_paths.platform_dir        = sprintf('%s/%s/data/delayed',local_paths.root_dir,server);
local_paths.deployment_name     = sprintf('%s/%s',local_paths.platform_dir,full_deployment_name);
local_paths.deployment_dir      = sprintf('%s/%s',local_paths.platform_dir,full_deployment_name);

%% Write KML
disp(['Creating ' kmlfile])
fid = fopen(kmlfile,'w');
fprintf(fid,'<?xml version="1.0" encoding="UTF-8"?>\n');
fprintf(fid,'<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">\n');
fprintf(fid,'<Folder>\n');
fprintf(fid,'<name>All NorGlider Deployments</name>\n');
fprintf(fid,'<open>1</open>\n');

%% Collect metadata
% Retrieve all deployments in spreadsheet
T = readtable(spreadsheet,"FileType","spreadsheet");

% Delete rows that dont have mission number
T(isnan(T.MISSIONNUMBER),:) = [];
% Delete rows that have STATUS listed as scheduled
T(contains(T.STATUS,'scheduled'),:) = [];
% Delete slocum missions listed as active or missing 

% List all deployments in a dialog box for the user to select
deployId = T.MISSIONNUMBER;
deployName = T.INTERNALMISSIONID;
num_missions = height(T);
deploymentNameStr = cell(num_missions,1);
deployments = cell(num_missions,1);
for i = 1:num_missions
%     deploymentNameStr{i} = [num2str(deployId(i)) ' - ' deployName{i}];
    full_deployment_name = sprintf('%03d-%s',deployId(i),deployName{i})
    switch T.GLIDERPLATFORM{i}
        case 'seaglider'
    path_deployment = fullfile(
end

%% --- Write kml ----------------------------
for i = 1:numel(missions)
    this_mission = missions{i};
    
    % SG or SL?
    if contains(this_mission(1:2),'sg')
        % this is a TEMP FIX, NACO simlink is blocked FE 7.6.23
%         this_mission_kmlfile = fullfile(WEBURL,'data_sg',this_mission,[this_mission '.kml']);
%         this_mission_local_kmlfile = fullfile('/Data/gfi/projects/naco/Op_resources',this_mission,[this_mission '.kml']);
        this_mission_kmlfile = fullfile(WEBURL,'data','real_time',[this_mission '.kml']);
        this_mission_local_kmlfile = fullfile(realtime_dir,[this_mission '.kml']);
    else
        this_mission_kmlfile = fullfile(WEBURL,'data','real_time',this_mission,[this_mission '.kml']);
        this_mission_local_kmlfile = fullfile(realtime_dir,this_mission,[this_mission '.kml']);
    end
    
    % If glider kml file exists
    if exist(this_mission_local_kmlfile,'file')
        fprintf(fid,'<NetworkLink>\n');
        fprintf(fid,'	<name>%s</name>\n',this_mission);
        fprintf(fid,'	<Link>\n');
        fprintf(fid,'		<href>%s</href>\n',this_mission_kmlfile);
        fprintf(fid,'		<refreshMode>onInterval</refreshMode>\n');
        fprintf(fid,'		<refreshInterval>600</refreshInterval>\n');
        fprintf(fid,'	</Link>\n');
        fprintf(fid,'</NetworkLink>\n');
    end
    clear this_mission_kmlfile
    
end

fprintf(fid,'<LookAt>\n');
fprintf(fid,'   <longitude>%s</longitude>\n','0');
fprintf(fid,'	<latitude>%s</latitude>\n','70');
fprintf(fid,'		<altitude>3000000</altitude>\n');
fprintf(fid,'		<range>1000</range>\n');
fprintf(fid,'		<tilt>0</tilt>\n');
fprintf(fid,'		<heading>0</heading>\n');
fprintf(fid,'		<altitudeMode>relativeToGround</altitudeMode>\n');
fprintf(fid,'</LookAt>\n');

fprintf(fid,'</Folder>\n');

fprintf(fid,'</kml>\n');

fclose(fid);