function update_active_norgliders_kml(realtime_dir, missions)
%--------------------------------------------------------------------------
% update_active_norgliders_kml(root_dir,list of mission)
%
% Updates the kml files of active gliders. 
% Called by launch_slocum_web_monitor.m
%
% Input arguments:
% realtime_dir:          root dir for real time gliders
% missions:              cell of missions
%
% Outputs:
% updated kml file
%
% History:
% -2014       ANFOG
%--------------------------------------------------------------------------
kmlfile = fullfile(realtime_dir,'active_norgliders.kml');
WEBURL = 'https://norgliders.gfi.uib.no'; 
disp(['Creating ' kmlfile])
fid = fopen(kmlfile,'w');
fprintf(fid,'<?xml version="1.0" encoding="UTF-8"?>\n');
fprintf(fid,'<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">\n');
fprintf(fid,'<Folder>\n');
fprintf(fid,'<name>Active NorGliders</name>\n');
fprintf(fid,'<open>1</open>\n');

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