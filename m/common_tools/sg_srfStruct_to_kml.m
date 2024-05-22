function [] = sg_srfStruct_to_kml(sg, sg_mission)
%--------------------------------------------------------------------------
% [] = srfStruct_to_kml(cfg)
% 
% Create kml file
%--------------------------------------------------------------------------

plot_DAC = 1;
WEBURL = 'https://norgliders.gfi.uib.no'; 
seaglider_icon = '/assets/img/sea_glider.png';
slocum_icon = '/assets/img/slocum_glider.png';
waypoint_icon = '/assets/img/star.png';
shield_icon = '/assets/img/shield.png';
sg_path = '/Data/gfi/projects/naco/gliderbak/';
%sg_op_res = '/Data/gfi/projects/naco/Op_resources/'; FE 7.6.23
sg_op_res = '/Data/gfi/projects/slocum/data/real_time';
RT_dir = '/Data/gfi/projects/slocum/data/real_time';

% Use this colour for glider track
% yellow
track_col = struct('durin','FFDE3163',...
'dvalin','FFDFFF00',...
'urd','FFFFBF00',...
'verd','FFFF7F50',...
'skuld','FFDE3163',...
'sg560','FF9FE2BF',...
'sg561','FF40E0D0',...
'odin','FF6495ED',...
'sg564','FFCCCCFF');

% DEV ONLY
% if nargin < 1
%     sg = 'sg564';
%     sg_mission = 'sg564_NorEMSO_Greenland_Feb2023';
%     %sg = 'sg563';
%     %sg_mission = 'sg563_SWOT_lofoten_Jan2023';
%     disp(['DEV ONLY!!! Using glider ' sg ' and deployment ' sg_mission])
% end
sn = sg(3:end);
%project_dir = fullfile(sg_op_res,sg_mission);FE 7.6.23
project_dir = fullfile(sg_op_res);

% Use this colour for glider track
% yellow
track_col = struct('durin','FFDE3163',...
'dvalin','FFDFFF00',...
'urd','FFFFBF00',...
'verd','FFFF7F50',...
'skuld','FFDE3163',...
'sg560','FF9FE2BF',...
'sg561','FF40E0D0',...
'odin','FF6495ED',...
'sg563','FF8E44AD',... 
'sg564','FFCCCCFF');
col = track_col.(sg);


disp([getUTC,': Creating kml file for ' sg ', ' sg_mission '.kml']);

%% READ FILES

% Read NetCDF file
sg_profile_struct = dir(fullfile(sg_path,sg,[sg '*profile.nc'])); % list of all files in directory
sg_profile_file = char(sg_profile_struct(1).name); % list of all file names
nc_file = fullfile(sg_path, sg, sg_profile_file);
d1 = loadnc(nc_file);

% Find number of dives
num_surfacings = height(d1.time);
if num_surfacings <= 1
	disp('The NetCDF file for this deployment contains no data. Exiting.');
    return
end

% Read latest log file
log_files = dir(fullfile(sg_path,sg,['p' sn '*.log']));
log_files = {log_files.name}';
sg_log_file = fullfile(sg_path,sg,log_files{end});
log_data = struct();
fid = fopen(sg_log_file);
while ~feof(fid)
    tline = fgetl(fid);
    if contains(tline, 'version:')
        loc = strfind(tline, ':');
        value = deblank(tline(loc(1)+2:end));
        og_data.version = value;
    elseif contains(tline, 'glider:')
        loc = strfind(tline, ':');
        value = deblank(tline(loc(1)+2:end));
        og_data.serial_number = value;
    elseif contains(tline, 'mission:')
        loc = strfind(tline, ':');
        value = deblank(tline(loc(1)+2:end));
        og_data.mission = value;
    elseif contains(tline, 'dive:')
        loc = strfind(tline, ':');
        value = deblank(tline(loc(1)+2:end));
        og_data.dive = value;
    elseif contains(tline, 'start:')
        loc = strfind(tline, ':');
        value = deblank(tline(loc(1)+2:end));
        og_data.start = value;
    elseif contains(tline(1),'$')
        loc = strfind(tline,',');
        first_loc = loc(1);
        varname = tline(2:first_loc-1);
        value = deblank(tline(first_loc+1:end));
        try
            log_data.(varname) = value;
        catch
            varname = ['X_' varname];
            log_data.(varname) = value;
        end
    end
end
fclose(fid);


% Read targets file
sg_target_file = fullfile(sg_path,sg,'targets');
latitude =[];
longitude =[];
names = {};
fid = fopen(sg_target_file);
while ~feof(fid)
    tline = fgetl(fid);
    if ~contains(tline(1),'/')
        spaces = strfind(tline,' ');
        % name
        name = deblank(tline(1:spaces(1)-1));
        % lat
        loc1 = strfind(tline,'lat');
        loc2 = find(spaces>loc1,1);
        nmealat = deblank(replace(tline(loc1+3:spaces(loc2)),'=',''));
        % lon
        loc1 = strfind(tline,'lon');
        loc2 = find(spaces>loc1,1);
        nmealon = deblank(replace(tline(loc1+3:spaces(loc2)),'=',''));
        % convert to decimal degrees
        [deglat, deglon] = nmea2deg(str2num(nmealat), str2num(nmealon));
        if ~isempty(deglat) && ~isempty(deglon)
            latitude(length(latitude)+1,1) = deglat;
            longitude(length(longitude)+1,1) = deglon;
            names{length(names)+1,1} = name;
        end
    end
end
fclose(fid);

waypoints.latitude = latitude;
waypoints.longitude = longitude;
waypoints.name = names;

% Get current waypoint from log
[lac,loc] = ismember(log_data.TGT_NAME, waypoints.name);
if lac
    waypoints.current.latitude = waypoints.latitude(loc);
    waypoints.current.longitude = waypoints.longitude(loc);
    waypoints.current.name = waypoints.name{loc};
else
    % Set to first waypoint - MAYBE CHANGE to not include
    waypoints.current.latitude = waypoints.latitude(1);
    waypoints.current.longitude = waypoints.longitude(1);
    waypoints.current.name = waypoints.name(1);
end


% Read EGO file
ego_file = fullfile(sg_path,sg,'json',[sg_mission '.json']);
ego_json_code = fileread(ego_file);
ego = jsondecode(ego_json_code);

% % if directory doesn't exit make one
% % This is an ugly hack (the best known way) to check if the directory exists.
% [status, attrout] = fileattrib(project_dir);
% if ~status
%     [status, message] = mkdir(project_dir);
% elseif ~attrout.directory
%     status = false;
%     message = 'not a directory';
% end

% Vars
GLIDER = ego.global_attributes.platform_code;
MISSION = ego.global_attributes.deployment_code;
outputKmlFilename = [ego.global_attributes.deployment_code,'.kml'];


%% Write KML file 
% - Create & write KML file
disp([getUTC,': Creating file: ' outputKmlFilename]);
fid = fopen(fullfile(project_dir,outputKmlFilename),'w');

% Start writing KML file
fprintf(fid,'<?xml version="1.0" encoding="UTF-8"?>\n');
fprintf(fid,'<kml xmlns="http://earth.google.com/kml/2.1">\n');
fprintf(fid,'<Document>\n');
fprintf(fid,'	<name>%s</name>\n',MISSION);
fprintf(fid,'\n');

fprintf(fid,'<!-- MAP LOCATION -->\n');
fprintf(fid,'<LookAt>\n');
fprintf(fid,'   <longitude>%s</longitude>\n',num2str(d1.end_longitude(end)));
fprintf(fid,'	<latitude>%s</latitude>\n',num2str(d1.end_latitude(end)));
fprintf(fid,'	<altitude>0</altitude>\n');
fprintf(fid,'	<range>50000</range>\n');
fprintf(fid,'	<tilt>0</tilt>\n');
fprintf(fid,'	<heading>0</heading>\n');
fprintf(fid,'	<altitudeMode>relativeToGround</altitudeMode>\n');
fprintf(fid,'</LookAt>\n');
fprintf(fid,'\n');
fprintf(fid,'<!-- START DEFINING STYLES -->\n');

% Create "surfacing" stylemap
fprintf(fid,'	<!-- Style Information for Surfacing -->\n');
fprintf(fid,'	<StyleMap id="msn_surface">\n');
fprintf(fid,'		<Pair>\n');
fprintf(fid,'			<key>normal</key>\n');
fprintf(fid,'			<styleUrl>#sn_surface</styleUrl>\n');
fprintf(fid,'		</Pair>\n');
fprintf(fid,'		<Pair>\n');
fprintf(fid,'			<key>highlight</key>\n');
fprintf(fid,'			<styleUrl>#sh_surface</styleUrl>\n');
fprintf(fid,'		</Pair>\n');
fprintf(fid,'	</StyleMap>\n');
fprintf(fid,'	<Style id="sh_surface">\n');
fprintf(fid,'		<IconStyle>\n');
fprintf(fid,'	<heading>0</heading>\n');
fprintf(fid,'			<scale>0.5</scale>\n');
fprintf(fid,'			<Icon>\n');
fprintf(fid,'				<href>http://maps.google.com/mapfiles/kml/pal4/icon48.png</href>\n'); % red square
fprintf(fid,'			</Icon>\n');
fprintf(fid,'		</IconStyle>\n');
fprintf(fid,'		<LabelStyle>\n');
fprintf(fid,'			<color>ffffffff</color>\n'); % white
fprintf(fid,'			<scale>0.5</scale>\n');
fprintf(fid,'		</LabelStyle>\n');
fprintf(fid,'		<ListStyle>\n');
fprintf(fid,'		</ListStyle>\n');
fprintf(fid,'	</Style>\n');
fprintf(fid,'	<Style id="sn_surface">\n');
fprintf(fid,'		<IconStyle>\n');
fprintf(fid,'			<scale>0.5</scale>\n');
fprintf(fid,'			<Icon>\n');
fprintf(fid,'				<href>http://maps.google.com/mapfiles/kml/pal4/icon48.png</href>\n'); % red square
fprintf(fid,'			</Icon>\n');
fprintf(fid,'		</IconStyle>\n');
fprintf(fid,'		<LabelStyle>\n');
fprintf(fid,'			<color>ffffffff</color>\n');
fprintf(fid,'			<scale>0.5</scale>\n');
fprintf(fid,'		</LabelStyle>\n');
fprintf(fid,'		<ListStyle>\n');
fprintf(fid,'		</ListStyle>\n');
fprintf(fid,'	</Style>\n');

% Create "track line" stylemap
fprintf(fid,'\n');
fprintf(fid,'	<!-- Style Information for Glider Track -->\n');
fprintf(fid,'	<Style id="yellowLine">\n');
fprintf(fid,'	  <LineStyle>\n');
fprintf(fid,'	    <color>%s</color>\n',col); 
fprintf(fid,'	    <width>3</width>\n');
fprintf(fid,'	  </LineStyle>\n');
fprintf(fid,'	</Style> \n');

% Create "waypoint line" stylemap
fprintf(fid,'\n');
fprintf(fid,'	<!-- Style Information for Glider Track -->\n');
fprintf(fid,'	<Style id="whiteLine">\n');
fprintf(fid,'	  <LineStyle>\n');
fprintf(fid,'	    <color>FFFFFFFF</color>\n');
fprintf(fid,'	    <width>0.5</width>\n');
fprintf(fid,'	  </LineStyle>\n');
fprintf(fid,'	</Style> \n');

% Create "current vector" stylemap
fprintf(fid,'\n');
fprintf(fid,'	<!-- Style Information for Surface drift arrow -->\n');
fprintf(fid,'	<Style id="greenLine">\n');
fprintf(fid,'	  <LineStyle>\n');
fprintf(fid,'	    <color>FFFFFFFF</color>\n');  %green
fprintf(fid,'	    <width>1</width>\n');
fprintf(fid,'	  </LineStyle>\n');
fprintf(fid,'	</Style> \n');
fprintf(fid,'\n');
fprintf(fid,'<!-- FINISHED DEFINING STYLES -->\n');


%% Write Deployment Location marker & data link
fprintf(fid,'\n');
fprintf(fid,'<!-- Deployment balloon -->\n');
fprintf(fid,'<Placemark>\n');
fprintf(fid,'	<name>Deployment</name>\n');
fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
fprintf(fid,'	<Style>\n');
fprintf(fid,'       <IconStyle>\n');
fprintf(fid,'           <color>ff00aa55</color>\n'); % FF0000 = red, old = ff00aa55
fprintf(fid,'			<Icon>\n');
fprintf(fid,'				<href>http://maps.google.com/mapfiles/kml/shapes/triangle.png</href>\n');
fprintf(fid,'			</Icon>\n');
fprintf(fid,'		</IconStyle>\n');
fprintf(fid,'		<LabelStyle>\n');
fprintf(fid,'			<color>ff00aa55</color>\n');
fprintf(fid,'		</LabelStyle>\n');
fprintf(fid,'		<ListStyle>\n');
fprintf(fid,'		</ListStyle>\n');
fprintf(fid,'		<BalloonStyle>\n');
fprintf(fid,'			<text><![CDATA[<iframe src=''%s'' width=600 height=400 frameborder=0 /> ]]></text>\n', WEBURL); % TODO - insert deployment text file overview here
fprintf(fid,'		</BalloonStyle>\n');
fprintf(fid,'	</Style>\n');
fprintf(fid,'	<Point>\n');
fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(d1.start_longitude(1)),num2str(d1.start_latitude(1)));
fprintf(fid,'	</Point>\n');
fprintf(fid,'</Placemark>\n');


%% Write Current Location marker & data link
fprintf(fid,'\n');
fprintf(fid,'<!-- Create marker at current glider location -->\n');
fprintf(fid,'<Placemark>\n');
fprintf(fid,'	<name>Last Surfacing: %s</name>\n',datestr(ut2mt(d1.time(end)),'HH:MM dd.mmm.yyyy'));
fprintf(fid,'<description>Last surfacing at %s Z.\n</description>\n',datestr(ut2mt(d1.time(end)),'HH:MM dd.mmm.yyyy'));
fprintf(fid,'	<Snippet maxLines="3"></Snippet>\n');
fprintf(fid,'	<Style>\n');
fprintf(fid,'		<IconStyle>\n');
fprintf(fid,'			<scale>2.0</scale>\n');
fprintf(fid,'			<heading>0</heading>\n');
fprintf(fid,'			<Icon>\n');
fprintf(fid,'				<href>%s</href>\n',fullfile(WEBURL,seaglider_icon));
fprintf(fid,'			</Icon>\n');
fprintf(fid,'		</IconStyle>\n');
fprintf(fid,'		<LabelStyle>\n');
fprintf(fid,'			<scale>0.7</scale>\n');
fprintf(fid,'		</LabelStyle>\n');
fprintf(fid,'		<BalloonStyle>\n');
fprintf(fid,'			<text><![CDATA[<iframe src=''%s'' width=940 height=820 frameborder=0 /> ]]></text>\n',WEBURL); %todo add proper surfacing info
fprintf(fid,'		</BalloonStyle>\n');
fprintf(fid,'	</Style>\n');
fprintf(fid,'	<Point>\n');
fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(d1.end_longitude(end)),num2str(d1.end_latitude(end)));
fprintf(fid,'	</Point>\n');
fprintf(fid,'</Placemark>\n');


%% Write placemark at current waypoint location
fprintf(fid,'\n');
fprintf(fid,'<!-- Create waypoint marker -->\n');
fprintf(fid,'<Placemark>\n');
fprintf(fid,'	<name>Current Waypoint</name>\n');
fprintf(fid,'	<visibility>1</visibility>\n');
fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
fprintf(fid,'	<Style>\n');
fprintf(fid,'		<IconStyle>\n');
%fprintf(fid,'			<color>ff0000ff</color>\n');
fprintf(fid,'			<scale>0.8</scale>\n');
fprintf(fid,'			<Icon>\n');
fprintf(fid,'				<href>%s</href>\n',fullfile(WEBURL,shield_icon));
fprintf(fid,'			</Icon>\n');
fprintf(fid,'			<hotSpot x="0.5" y="0" xunits="fraction" yunits="fraction"/>\n');
fprintf(fid,'		</IconStyle>\n');
fprintf(fid,'		<LabelStyle>\n');
fprintf(fid,'			<color>ff0000ff</color>\n');
fprintf(fid,'			<scale>0.8</scale>\n');
fprintf(fid,'		</LabelStyle>\n');
fprintf(fid,'		<BalloonStyle>\n');
fprintf(fid,'			<text><![CDATA[<iframe src=''%s'' width=600 height=400 frameborder=0 /> ]]></text>\n',WEBURL);
fprintf(fid,'		</BalloonStyle>\n');
fprintf(fid,'	</Style>\n');
fprintf(fid,'	<Point>\n');

wptLon = waypoints.current.longitude;
wptLat = waypoints.current.latitude;

fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(wptLon),num2str(wptLat));
fprintf(fid,'	</Point>\n');
fprintf(fid,'</Placemark>\n');


%% Waypoints
fprintf(fid,'			<Folder>\n');
fprintf(fid,'				<name>Waypoints</name>\n');
fprintf(fid,'				<visibility>1</visibility>\n');
fprintf(fid,'				<open>0</open>\n');

% Plot waypoints line
fprintf(fid,'		<Placemark>\n');
fprintf(fid,'			<name>Wapoints Line</name>\n');
fprintf(fid,'			<styleUrl>#whiteLine</styleUrl>\n');
fprintf(fid,'			<LineString>\n');
fprintf(fid,'				<tessellate>1</tessellate>\n');
fprintf(fid,'				<coordinates>\n');
for i = 1:numel(waypoints.longitude)
    if ~isnan(waypoints.longitude(i))
        fprintf(fid,' %s,%s,0',num2str(waypoints.longitude(i)),num2str(waypoints.latitude(i)));
    end
end
fprintf(fid,'               </coordinates>\n');
fprintf(fid,'			</LineString>\n');
fprintf(fid,'		</Placemark>\n');

% Waypoint symbols and labels
fprintf(fid,'			<Folder>\n');
fprintf(fid,'				<name>Waypoints</name>\n');
fprintf(fid,'				<visibility>1</visibility>\n');
fprintf(fid,'				<open>0</open>\n');
for i = 1:numel(waypoints.longitude)
    fprintf(fid,'<Placemark>\n');
    fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
    fprintf(fid,'	<Style>\n');
    fprintf(fid,'		<IconStyle>\n');
    fprintf(fid,'			<scale>0.7</scale>\n');
    fprintf(fid,'			<heading>0</heading>\n');
    fprintf(fid,'			<Icon>\n');
    fprintf(fid,'				<href>%s</href>\n',fullfile(WEBURL,waypoint_icon));
    % fprintf(fid,'				<href>http://maps.google.com/mapfiles/kml/pal4/icon57.png</href>\n'); %icon48
    fprintf(fid,'			</Icon>\n');
    fprintf(fid,'		</IconStyle>\n');
    fprintf(fid,'		<LabelStyle>\n');
    fprintf(fid,'			<scale>0.60</scale>\n');
    fprintf(fid,'		</LabelStyle>\n');
    fprintf(fid,'		<BalloonStyle>\n');
    fprintf(fid,'			<text><![CDATA[<iframe width=940 height=820 frameborder=0 /> ]]>%s</text>\n',waypoints.name{i});
    fprintf(fid,'		</BalloonStyle>\n');
    fprintf(fid,'	</Style>\n');
    fprintf(fid,'	<Point>\n');
    fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(waypoints.longitude(i)),num2str(waypoints.latitude(i)));
    fprintf(fid,'	</Point>\n');
    fprintf(fid,'</Placemark>\n');
end
fprintf(fid,'			</Folder>\n');

% Waypoint symbols no labels
fprintf(fid,'			<Folder>\n');
fprintf(fid,'				<name>Waypoints Labels</name>\n');
fprintf(fid,'				<visibility>1</visibility>\n');
fprintf(fid,'				<open>0</open>\n');
for i = 1:numel(waypoints.longitude)
    fprintf(fid,'<Placemark>\n');
    fprintf(fid,'	   <name>%s</name>\n',waypoints.name{i});
    fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
    fprintf(fid,'	<Style>\n');
    fprintf(fid,'		<IconStyle>\n');
    fprintf(fid,'			<scale>0.7</scale>\n');
    fprintf(fid,'			<heading>0</heading>\n');
    fprintf(fid,'			<Icon>\n');
    fprintf(fid,'				<href>%s</href>\n',fullfile(WEBURL,waypoint_icon));
    % fprintf(fid,'				<href>http://maps.google.com/mapfiles/kml/pal4/icon57.png</href>\n'); %icon48
    fprintf(fid,'			</Icon>\n');
    fprintf(fid,'		</IconStyle>\n');
    fprintf(fid,'		<LabelStyle>\n');
    fprintf(fid,'			<scale>0.60</scale>\n');
    fprintf(fid,'		</LabelStyle>\n');
    fprintf(fid,'		<BalloonStyle>\n');
    fprintf(fid,'			<text><![CDATA[<iframe width=940 height=820 frameborder=0 /> ]]>%s</text>\n',waypoints.name{i});
    fprintf(fid,'		</BalloonStyle>\n');
    fprintf(fid,'	</Style>\n');
    fprintf(fid,'	<Point>\n');
    fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(waypoints.longitude(i)),num2str(waypoints.latitude(i)));
    fprintf(fid,'	</Point>\n');
    fprintf(fid,'</Placemark>\n');
end
fprintf(fid,'			</Folder>\n');

fprintf(fid,'			</Folder>\n');

%% Create markers for all surfacings
fprintf(fid,'			<Folder>\n');
fprintf(fid,'				<name>Glider Track</name>\n');
fprintf(fid,'				<visibility>0</visibility>\n');
fprintf(fid,'				<open>0</open>\n');

% Plot glider track line
fprintf(fid,'		<Placemark>\n');
fprintf(fid,'			<name>Glider Track</name>\n');
fprintf(fid,'			<styleUrl>#yellowLine</styleUrl>\n');
fprintf(fid,'			<LineString>\n');
fprintf(fid,'				<tessellate>1</tessellate>\n');
fprintf(fid,'				<coordinates>\n');
for i = 1:num_surfacings
    if ~isnan(d1.longitude)
        fprintf(fid,' %s,%s,0',num2str(d1.start_longitude(i)),num2str(d1.start_latitude(i)));
    end
end
% NOTE: We are plotting the points from the start of every dive, add the
% end point of the final dive to connect to the current poisiton icon. We
% may want to edit configuration to show surface drift - althoug unsure if
% gps is correctted to reflect drift.
fprintf(fid,' %s,%s,0',num2str(d1.end_longitude(end)),num2str(d1.end_latitude(end)));
fprintf(fid,'               </coordinates>\n');
fprintf(fid,'			</LineString>\n');
fprintf(fid,'		</Placemark>\n');

% Create markers for all surfacings
fprintf(fid,'			<Folder>\n');
fprintf(fid,'				<name>Surfacings</name>\n');
fprintf(fid,'				<visibility>0</visibility>\n');
fprintf(fid,'				<open>0</open>\n');
dayno = NaN;
for ii = (num_surfacings-1):-1:2
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<TimeStamp>\n');
        fprintf(fid,'  <when>%s</when>\n',datestr(ut2mt(d1.start_time(ii)),'yyyy.mm.ddTHH:MMZ')); %yyyy-mm-ddTHH:MMZ
        fprintf(fid,'</TimeStamp>\n');
        fprintf(fid,'	<visibility>0</visibility>\n');
        fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
        fprintf(fid,'	<Style>\n');
        fprintf(fid,'		<IconStyle>\n');
        fprintf(fid,'			<scale>0.5</scale>\n');
        fprintf(fid,'			<heading>0</heading>\n');
        fprintf(fid,'			<Icon>\n');
        
        % Use different marker when data is avilable
        if 0 %exist(fullfile(PROJECTDIR,'ascii',[char(logs{ii, 'segment_name'}),'_sbd.dat']),'file')
            fprintf(fid,'				<href>http://maps.google.com/mapfiles/kml/pal4/icon48.png</href>\n');
        else
            fprintf(fid,'				<href>http://maps.google.com/mapfiles/kml/pal4/icon57.png</href>\n');
        end
        
        fprintf(fid,'			</Icon>\n');
        fprintf(fid,'		</IconStyle>\n');
        fprintf(fid,'		<LabelStyle>\n');
        fprintf(fid,'			<scale>0.60</scale>\n');
        fprintf(fid,'		</LabelStyle>\n');
        fprintf(fid,'		<BalloonStyle>\n');
        fprintf(fid,'			<text><![CDATA[<iframe src=''%s'' width=940 height=820 frameborder=0 /> ]]></text>\n',[WEBURL]);
        fprintf(fid,'		</BalloonStyle>\n');
        fprintf(fid,'	</Style>\n');
        fprintf(fid,'	<Point>\n');
        fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(d1.start_longitude(ii)),num2str(d1.start_latitude(ii)));
        fprintf(fid,'	</Point>\n');
        fprintf(fid,'</Placemark>\n');
end
fprintf(fid,'			</Folder>\n');


% Create markers for all surfacings with labels
fprintf(fid,'			<Folder>\n');
fprintf(fid,'				<name>Surfacings Labels</name>\n');
fprintf(fid,'				<visibility>0</visibility>\n');
fprintf(fid,'				<open>0</open>\n');
for ii = (num_surfacings-1):-1:2
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<TimeStamp>\n');
        fprintf(fid,'  <when>%s</when>\n',datestr(ut2mt(d1.start_time(ii)),'yyyy.mm.ddTHH:MMZ')); %yyyy-mm-ddTHH:MMZ
        fprintf(fid,'</TimeStamp>\n');
        fprintf(fid,'   <name>%s</name>\n',datestr(ut2mt(d1.start_time(ii)),'HH:MM dd.mmm'));
        fprintf(fid,'	<visibility>0</visibility>\n');
        fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
        fprintf(fid,'	<Style>\n');
        fprintf(fid,'		<IconStyle>\n');
        fprintf(fid,'			<scale>0.5</scale>\n');
        fprintf(fid,'			<heading>0</heading>\n');
        fprintf(fid,'			<Icon>\n');
        
        % Use different marker when data is avilable
        %file = fullfile(WEBURL,'data','real_time',MISSION,'segments',strrep(char(logs{ii, 'segment_name'}),'-','_'),[char(logs{ii, 'segment_name'}) '-m_depth.png']); 
        %localfile = fullfile('/Data/gfi/projects/slocum/data/real_time/',MISSION,'segments',strrep(char(logs{ii, 'segment_name'}),'-','_'),[char(logs{ii, 'segment_name'}) '-m_depth.png']); 
        if 0 %exist(localfile,'file')
            have_files = 1;
            fprintf(fid,'				<href>http://maps.google.com/mapfiles/kml/pal4/icon48.png</href>\n');
        else
            have_files = 0;
            fprintf(fid,'				<href>http://maps.google.com/mapfiles/kml/pal4/icon57.png</href>\n');
        end
        
        fprintf(fid,'			</Icon>\n');
        fprintf(fid,'		</IconStyle>\n');
        fprintf(fid,'		<LabelStyle>\n');
        fprintf(fid,'			<scale>0.60</scale>\n');
        fprintf(fid,'		</LabelStyle>\n');
        fprintf(fid,'		<BalloonStyle>\n');
        if have_files
            fprintf(fid,'			<text><![CDATA[<iframe src=''%s'' width=940 height=820 frameborder=0 /> ]]></text>\n',file);
        end
        fprintf(fid,'		</BalloonStyle>\n');
        fprintf(fid,'	</Style>\n');
        fprintf(fid,'	<Point>\n');
        fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(d1.start_longitude(ii)),num2str(d1.start_latitude(ii)));
        fprintf(fid,'	</Point>\n');
        fprintf(fid,'</Placemark>\n');
end
fprintf(fid,'			</Folder>\n');

fprintf(fid,'			</Folder>\n');


%% Plot DAC
if plot_DAC
    % --- Create depth averaged current vectors
    fprintf(fid,'			<Folder>\n');
    fprintf(fid,'				<name>Depth Averaged Currents</name>\n');
    fprintf(fid,'				<visibility>0</visibility>\n');
    fprintf(fid,'				<open>0</open>\n');
    
    for ii = (num_surfacings):-1:1
            try
                vx = d1.depth_avg_curr_east(ii); % srfStruct(ii,1).Sensors.m_water_vx(1);
                vy = d1.depth_avg_curr_north(ii); % srfStruct(ii,1).Sensors.m_water_vy(1);
            catch
                vx = 0;
                vy = 0;
            end
            
            fprintf(fid,'		<Placemark>\n');
            fprintf(fid,'			<visibility>0</visibility>\n');
            fprintf(fid,'           <TimeStamp>\n');
            fprintf(fid,'               <when>%s</when>\n',datestr(ut2mt(d1.time(ii)),'dd.mmm.yyyy HH:MM'));
            fprintf(fid,'           </TimeStamp>\n');
            fprintf(fid,'			<name>DAC: vx= %4.2g m/s, vy= %4.2g m/s</name>\n',vx,vy); %srfStruct(ii,1).Sensors.m_water_vx(1),srfStruct(ii,1).Sensors.m_water_vy(1));
            fprintf(fid,'			<styleUrl>#greenLine</styleUrl>\n');
            fprintf(fid,'			<LineString>\n');
            fprintf(fid,'				<tessellate>1</tessellate>\n');
            fprintf(fid,'				<coordinates>\n');
            
            [theta,vel] = cart2pol(vx,vy);
            brg=90-rad2deg(theta);
            
            %vel = vel*3600*DAC_HRS/111120; % convert m/s to degrees travelled in 'cfg.DAC_HRS' hours
            
            %Remove NaNs
            if isnan(vel)
                vel=0;
                brg=0;
            end
            
            % Plot DAC vector
            %sca = 1;
            x1 = d1.longitude(ii); %srfStruct(ii,1).GPSLocation(2); IS THUIS RIGHT?????
            y1 = d1.latitude(ii); % srfStruct(ii,1).GPSLocation(1);
            x2 = x1 + vel*cos(deg2rad(90-brg));
            y2 = y1 + vel*sin(deg2rad(90-brg));
            fprintf(fid,' %s,%s,0',num2str(x1),num2str(y1));
            fprintf(fid,' %s,%s,0',num2str(x2),num2str(y2));
            
            % These are the arrow heads, which i cant get pointing the right way
%             x3 = x1 + sca*vel*cos(deg2rad((90-brg)-2));
%             y3 = y1 + sca*vel*sin(deg2rad((90-brg)-2));
%             x4 = x1 + sca*vel*cos(deg2rad((90-brg)+2));
%             y4 = y1 + sca*vel*sin(deg2rad((90-brg)+2));
%             fprintf(fid,' %s,%s,0',num2str(x3),num2str(y3));
%             fprintf(fid,' %s,%s,0',num2str(x2),num2str(y2));
%             fprintf(fid,' %s,%s,0',num2str(x4),num2str(y4));
      
            fprintf(fid,'\n               </coordinates>\n');
            fprintf(fid,'			</LineString>\n');
            fprintf(fid,'		</Placemark>\n');
    end
    
    fprintf(fid,'			</Folder>\n');
end

fprintf(fid,'</Document>\n');
fprintf(fid,'</kml>\n');

fclose(fid);

disp([getUTC,': Finished writing kml']);
