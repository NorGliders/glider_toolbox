function [] = srfStruct_to_kml(processed_logs_file, ego_file)
%--------------------------------------------------------------------------
% [] = srfStruct_to_kml(cfg)
% 
% Create kml file
%--------------------------------------------------------------------------

DAC_HRS = 4; % convert m/s to degrees travelled in 'cfg.DAC_HRS' hours
plot_DAC = 1;
have_files = 1;

%DEV
if nargin < 1
    processed_logs_file = '/Data/gfi/projects/slocum/data/real_time/202210_sl_urd_noremso_iceland/202210_sl_urd_noremso_iceland_processed_logs.dat';
    ego_file = '/Data/gfi/projects/slocum/data/real_time/202210_sl_urd_noremso_iceland.json';
end

% Read EGO file
logs = importProcessedLogList(processed_logs_file);
ego_json_code = fileread(ego_file);
ego = jsondecode(ego_json_code);
fileparts(processed_logs_file)

% Vars
GLIDER = ego.global_attributes.platform_code;
MISSION = ego.global_attributes.deployment_code;
outputKmlFilename = [ego.global_attributes.deployment_code,'.kml'];
transect = {'24hr','48hr','mission'};    

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
col = track_col.(GLIDER);

% Data path and URLs
PROJECTDIR = fileparts(processed_logs_file);

WEBURLIMG = fullfile(fileparts(processed_logs_file),'img'); 
WEBURL = 'https://norgliders.gfi.uib.no'; 
glider_icon = '/assets/img/slocum_glider.png'; %glider_kml_80.png';
shield_icon = '/assets/img/shield.png';
% webRoot    = ['http://anfog.ecm.uwa.edu.au/',cfg.DATA_PATH];
% webRoot    = ['http://changethis/',cfg.DATA_PATH];
% altimUrl   = ['http://anfog.ecm.uwa.edu.au/IMOS/OceanCurrents/',cfg.PROJECT,'/'];
% altimUrl   = ['http://changethis/IMOS/OceanCurrents/',cfg.PROJECT,'/'];

% Remove logs with no position or GPS information, 
bad_index = (isnan(logs{:, 'GPS_lat'}) + isnan(logs{:, 'GPS_lon'}) + isnat(logs{:, 'current_time'})) > 0;
logs(bad_index,:) = [];

% Find latest good surfacing
num_surfacings = height(logs);
if num_surfacings <= 1
	disp([': The processed logs file for glider ' GLIDER ' contains no data. Exiting.']);
    return
end


% %% --- Read transects.txt file if it exists and create links for each transect --- 
% if exist(fullfile(PROJECTDIR,'transect.txt'),'file')
%     fid2 = fopen(fullfile(PROJECTDIR,'transect.txt'));
%     j = length(transect);
%     while 1
%         j = j+1;
%         tline = fgetl(fid2);
%         if ~ischar(tline), break, end;
%             ind           = find(tline==',');
%             tr_start      = datenum(tline(1:ind(1)-1));
%             tr_end        = datenum(tline(ind(1)+1:end));
%             transect{1,j} = [datestr(tr_start,30),'-', datestr(tr_end,30)];
%        end
%     fclose(fid2);
% end



%% --- 1. Create KML file ---
% - Create & write KML file
disp([getUTC,': Creating file: ' outputKmlFilename]);
fid = fopen(fullfile(PROJECTDIR,outputKmlFilename),'w');

% Start writing KML file
fprintf(fid,'<?xml version="1.0" encoding="UTF-8"?>\n');
fprintf(fid,'<kml xmlns="http://earth.google.com/kml/2.1">\n');
fprintf(fid,'<Document>\n');
fprintf(fid,'	<name>%s</name>\n',outputKmlFilename);
fprintf(fid,'\n');

fprintf(fid,'<!-- MAP LOCATION -->\n');
fprintf(fid,'<LookAt>\n');
fprintf(fid,'   <longitude>%s</longitude>\n',num2str(logs{end, 'GPS_lon'}));
fprintf(fid,'	<latitude>%s</latitude>\n',num2str(logs{end, 'GPS_lat'}));
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
fprintf(fid,'			<text><![CDATA[<iframe src=''%s'' width=600 height=400 frameborder=0 /> ]]></text>\n',[WEBURL]); % TODO - insert deployment text file overview here
fprintf(fid,'		</BalloonStyle>\n');
fprintf(fid,'	</Style>\n');
fprintf(fid,'	<Point>\n');
fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(logs{1, 'GPS_lon'}),num2str(logs{1, 'GPS_lat'}));
fprintf(fid,'	</Point>\n');
fprintf(fid,'</Placemark>\n');


%% Write Current Location marker & data link
fprintf(fid,'\n');
fprintf(fid,'<!-- Create marker at current glider location -->\n');
fprintf(fid,'<Placemark>\n');
fprintf(fid,'	<name>Last Surfacing: %s</name>\n',datestr(logs{end, 'current_time'},'dd.mmm HH:MM'));
fprintf(fid,'<description>Last surfacing at %s Z.\nBecause: %s.\nDevice string: %s</description>\n',datestr(logs{end, 'current_time'},'dd.mmm.yyyy HH:MM'), char(logs{end, 'because'}), char(logs{end, 'device_str'}));
fprintf(fid,'	<Snippet maxLines="3"></Snippet>\n');
fprintf(fid,'	<Style>\n');
fprintf(fid,'		<IconStyle>\n');
fprintf(fid,'			<scale>2.0</scale>\n');
fprintf(fid,'			<heading>0</heading>\n');
fprintf(fid,'			<Icon>\n');
fprintf(fid,'				<href>%s</href>\n',fullfile(WEBURL,glider_icon));
fprintf(fid,'			</Icon>\n');
fprintf(fid,'		</IconStyle>\n');
fprintf(fid,'		<LabelStyle>\n');
fprintf(fid,'			<scale>0.7</scale>\n');
fprintf(fid,'		</LabelStyle>\n');
fprintf(fid,'		<BalloonStyle>\n');
fprintf(fid,'			<text><![CDATA[<iframe src=''%s'' width=940 height=820 frameborder=0 /> ]]></text>\n',[WEBURL]); %todo add proper surfacing info
fprintf(fid,'		</BalloonStyle>\n');
fprintf(fid,'	</Style>\n');
fprintf(fid,'	<Point>\n');
fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(logs{end, 'GPS_lon'}),num2str(logs{end, 'GPS_lat'}));
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
fprintf(fid,'			<text><![CDATA[<iframe src=''%s'' width=600 height=400 frameborder=0 /> ]]></text>\n',[WEBURL]);
fprintf(fid,'		</BalloonStyle>\n');
fprintf(fid,'	</Style>\n');
fprintf(fid,'	<Point>\n');
% if wpt is Nan, use previous until valid pt achieved
i=num_surfacings;
wptLon = logs{i, 'c_wpt_lon'};  % nmea2deg(logs{i, 'c_wpt_lon'}); %nmea2deg(logs{i, 'c_wpt_lon'});  %   srfStruct(numSurfacings,1).Waypoint.Lon;
wptLat = logs{i, 'c_wpt_lat'};   %nmea2deg(logs{i, 'c_wpt_lat'}); %%srfStruct(numSurfacings,1).Waypoint.Lat;
while isnan(wptLon)==1
    i = i-1;
    if i<1,break,end
    wptLon = logs{i, 'c_wpt_lon'};  
    wptLat = logs{i, 'c_wpt_lat'};  
end
% Hack convert from NMEA to dd

fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(wptLon),num2str(wptLat));
fprintf(fid,'	</Point>\n');
fprintf(fid,'</Placemark>\n');


% %% Write Cross section data link
% transect2 = 'mission';
% fprintf(fid,'\n');
% fprintf(fid,'<!-- Create cross section plot link -->\n');
% fprintf(fid,'<Placemark>\n');
% fprintf(fid,'	<name>Science Cross Section Data</name>\n');
% fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
% fprintf(fid,'	<Style>\n');
% fprintf(fid,'		<IconStyle>\n');
% fprintf(fid,'			<Icon>\n');
% fprintf(fid,'			</Icon>\n');
% fprintf(fid,'		</IconStyle>\n');
% fprintf(fid,'		<LabelStyle>\n');
% fprintf(fid,'			<color>00ffffff</color>\n');
% fprintf(fid,'			<scale>0</scale>\n');
% fprintf(fid,'		</LabelStyle>\n');
% fprintf(fid,'		<ListStyle>\n');
% fprintf(fid,'		</ListStyle>\n');
% fprintf(fid,'		<BalloonStyle>\n');
% fprintf(fid,'			<text><![CDATA[<iframe src=''%s'' width=760 height=700 frameborder=0 /> ]]></text>\n',[WEBURL '\testing.png']);
% fprintf(fid,'		</BalloonStyle>\n');
% fprintf(fid,'	</Style>\n');
% fprintf(fid,'	<Point>\n');
% fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(srfStruct(numSurfacings,1).GPSLocation(2)),num2str(srfStruct(numSurfacings,1).GPSLocation(1)));
% fprintf(fid,'	</Point>\n');
% fprintf(fid,'</Placemark>\n');


% %% Write TBD Time Series data link
fprintf(fid,'\n');
fprintf(fid,'<!-- Create tbd tser plot link -->\n');
fprintf(fid,'<Placemark>\n');
fprintf(fid,'	<name>Science Time Series Data</name>\n');
fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
fprintf(fid,'	<Style>\n');
fprintf(fid,'		<IconStyle>\n');
fprintf(fid,'			<Icon>\n');
fprintf(fid,'			</Icon>\n');
fprintf(fid,'		</IconStyle>\n');
fprintf(fid,'		<LabelStyle>\n');
fprintf(fid,'			<color>00ffffff</color>\n');
fprintf(fid,'			<scale>0</scale>\n');
fprintf(fid,'		</LabelStyle>\n');
fprintf(fid,'		<ListStyle>\n');
fprintf(fid,'		</ListStyle>\n');
fprintf(fid,'		<BalloonStyle>\n');
fprintf(fid,'			<text><![CDATA[<iframe src=''%s'' width=760 height=700 frameborder=0 /> ]]></text>\n',fullfile(WEBURL,'data','real_time',MISSION,'figures','temperature_distance.png'));
fprintf(fid,'		</BalloonStyle>\n');
fprintf(fid,'	</Style>\n');
fprintf(fid,'	<Point>\n');
fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(logs{1, 'GPS_lon'}),num2str(logs{1, 'GPS_lat'}));
fprintf(fid,'	</Point>\n');
fprintf(fid,'</Placemark>\n');


% %% Write SBD Time Series data link
fprintf(fid,'\n');
fprintf(fid,'<!-- Create sbd tser plot link -->\n');
fprintf(fid,'<Placemark>\n');
fprintf(fid,'	<name>Eng Time Series Data</name>\n');
fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
fprintf(fid,'	<Style>\n');
fprintf(fid,'		<IconStyle>\n');
fprintf(fid,'			<Icon>\n');
fprintf(fid,'			</Icon>\n');
fprintf(fid,'		</IconStyle>\n');
fprintf(fid,'		<LabelStyle>\n');
fprintf(fid,'			<color>00ffffff</color>\n');
fprintf(fid,'			<scale>0</scale>\n');
fprintf(fid,'		</LabelStyle>\n');
fprintf(fid,'		<ListStyle>\n');
fprintf(fid,'		</ListStyle>\n');
fprintf(fid,'		<BalloonStyle>\n');
fprintf(fid,'			<text><![CDATA[<iframe src=''%s'' width=760 height=700 frameborder=0 /> ]]></text>\n',fullfile(WEBURL,'data','real_time',MISSION,'figures','m_de_oil_vol.png'));
fprintf(fid,'		</BalloonStyle>\n');
fprintf(fid,'	</Style>\n');
fprintf(fid,'	<Point>\n');
fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(logs{1, 'GPS_lon'}),num2str(logs{1, 'GPS_lat'}));
fprintf(fid,'	</Point>\n');
fprintf(fid,'</Placemark>\n');


% %% Write SRF Time Series data link
fprintf(fid,'\n');
fprintf(fid,'<!-- Create SRF time series plot balloon -->\n');
fprintf(fid,'<Placemark>\n');
fprintf(fid,'	<name>SRF Time Series</name>\n');
fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
fprintf(fid,'	<Style>\n');
fprintf(fid,'		<IconStyle>\n');
fprintf(fid,'			<Icon>\n');
fprintf(fid,'			</Icon>\n');
fprintf(fid,'		</IconStyle>\n');
fprintf(fid,'		<LabelStyle>\n');
fprintf(fid,'			<color>00ffffff</color>\n');
fprintf(fid,'			<scale>0</scale>\n');
fprintf(fid,'		</LabelStyle>\n');
fprintf(fid,'		<ListStyle>\n');
fprintf(fid,'		</ListStyle>\n');
fprintf(fid,'		<BalloonStyle>\n');
fprintf(fid,'			<text><![CDATA[<iframe src=''%s'' width=760 height=700 frameborder=0 /> ]]></text>\n',fullfile(WEBURL,'data','real_time',MISSION,'figures','surface','m_avg_upward_inflection_time.png'));
fprintf(fid,'		</BalloonStyle>\n');
fprintf(fid,'	</Style>\n');
fprintf(fid,'	<Point>\n');
fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(logs{1, 'GPS_lon'}),num2str(logs{1, 'GPS_lat'}));
fprintf(fid,'	</Point>\n');
fprintf(fid,'</Placemark>\n');


%% Weather link
fprintf(fid,'\n');
fprintf(fid,'<!-- Create weather balloon -->\n');
fprintf(fid,'<Placemark>\n');
fprintf(fid,'	<name>Weather</name>\n');
fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
fprintf(fid,'	<Style>\n');
fprintf(fid,'		<IconStyle>\n');
fprintf(fid,'			<Icon>\n');
fprintf(fid,'			</Icon>\n');
fprintf(fid,'		</IconStyle>\n');
fprintf(fid,'		<LabelStyle>\n');
fprintf(fid,'			<color>00ffffff</color>\n');
fprintf(fid,'			<scale>0</scale>\n');
fprintf(fid,'		</LabelStyle>\n');
fprintf(fid,'		<ListStyle>\n');
fprintf(fid,'		</ListStyle>\n');
fprintf(fid,'		<BalloonStyle>\n');
fprintf(fid,'			<text><![CDATA[<iframe src=''%s%s_%s'' width=800 height=700 frameborder=0 /> ]]></text>\n','https://www.barentswatch.no/bolgevarsel/marinogram/',num2str(logs{end, 'GPS_lon'}),num2str(logs{end, 'GPS_lat'}));
fprintf(fid,'		</BalloonStyle>\n');
fprintf(fid,'	</Style>\n');
fprintf(fid,'	<Point>\n');
fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(logs{1, 'GPS_lon'}),num2str(logs{1, 'GPS_lat'}));
fprintf(fid,'	</Point>\n');
fprintf(fid,'</Placemark>\n');


% 
%% --- Power Usage data link
fprintf(fid,'\n');
fprintf(fid,'<!-- Create power usage plot balloon -->\n');
fprintf(fid,'<Placemark>\n');
fprintf(fid,'	<name>Power Usage</name>\n');
fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
fprintf(fid,'	<Style>\n');
fprintf(fid,'		<IconStyle>\n');
fprintf(fid,'			<Icon>\n');
fprintf(fid,'			</Icon>\n');
fprintf(fid,'		</IconStyle>\n');
fprintf(fid,'		<LabelStyle>\n');
fprintf(fid,'			<color>00ffffff</color>\n');
fprintf(fid,'			<scale>0</scale>\n');
fprintf(fid,'		</LabelStyle>\n');
fprintf(fid,'		<ListStyle>\n');
fprintf(fid,'		</ListStyle>\n');
fprintf(fid,'		<BalloonStyle>\n');
fprintf(fid,'			<text><![CDATA[<iframe src=%s width=500 frameborder=0 /> ]]></text>\n',fullfile(WEBURL,'data','real_time',MISSION,'figures','surface','Battery_diagnostics_current.png'));
fprintf(fid,'		</BalloonStyle>\n');
fprintf(fid,'	</Style>\n');
fprintf(fid,'	<Point>\n');
fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(logs{1, 'GPS_lon'}),num2str(logs{1, 'GPS_lat'}));
fprintf(fid,'	</Point>\n');
fprintf(fid,'</Placemark>\n');
% 
% % --- Network link to targets.kml
% fprintf(fid,'\n');
% fprintf(fid,'<!-- Create targets network link -->\n');
% fprintf(fid,'<NetworkLink>\n');
% fprintf(fid,'	<name>Current Waypoints</name>\n');
% fprintf(fid,'		<Style>\n');
% fprintf(fid,'			<ListStyle>\n');
% fprintf(fid,'				<listItemType>checkHideChildren</listItemType>\n');
% fprintf(fid,'			</ListStyle>\n');
% fprintf(fid,'		</Style>\n');
% fprintf(fid,'	<Link>\n');
% fprintf(fid,'		<href>%scurrent_waypoints.kml</href>\n',WEBURL);
% fprintf(fid,'		<refreshMode>onInterval</refreshMode>\n');
% fprintf(fid,'		<refreshInterval>300</refreshInterval>\n');
% fprintf(fid,'	</Link>\n');
% fprintf(fid,'</NetworkLink>\n');

% % --- Network link to project_plan.kml
% fprintf(fid,'\n');
% fprintf(fid,'<!-- Create project plan network link -->\n');
% fprintf(fid,'<NetworkLink>\n');
% fprintf(fid,'	<name>Project Plan</name>\n');
% fprintf(fid,'		<Style>\n');
% fprintf(fid,'			<ListStyle>\n');
% fprintf(fid,'				<listItemType>checkHideChildren</listItemType>\n');
% fprintf(fid,'			</ListStyle>\n');
% fprintf(fid,'		</Style>\n');
% fprintf(fid,'	<Link>\n');
% fprintf(fid,'		<href>%sproject_plan.kml</href>\n',WEBURL);
% fprintf(fid,'		<refreshMode>onInterval</refreshMode>\n');
% fprintf(fid,'		<refreshInterval>300</refreshInterval>\n');
% fprintf(fid,'	</Link>\n');
% fprintf(fid,'</NetworkLink>\n');
% 
% % --- Network link to hazzards.kmlproject_plan
% fprintf(fid,'\n');
% fprintf(fid,'<!-- Create hazzards network link -->\n');
% fprintf(fid,'<NetworkLink>\n');
% fprintf(fid,'	<name>Hazzards</name>\n');
% fprintf(fid,'		<Style>\n');
% fprintf(fid,'			<ListStyle>\n');
% fprintf(fid,'				<listItemType>checkHideChildren</listItemType>\n');
% fprintf(fid,'			</ListStyle>\n');
% fprintf(fid,'		</Style>\n');
% fprintf(fid,'	<Link>\n');
% fprintf(fid,'		<href>%shazzards.kml</href>\n',WEBURL);
% fprintf(fid,'		<refreshMode>onInterval</refreshMode>\n');
% fprintf(fid,'		<refreshInterval>300</refreshInterval>\n');
% fprintf(fid,'	</Link>\n');
% fprintf(fid,'</NetworkLink>\n');


% --- Network link to OceanCurrents KML
% fprintf(fid,'\n');
% fprintf(fid,'<!-- Create OceanCurrents network link -->\n');
% fprintf(fid,'<NetworkLink>\n');
% fprintf(fid,'	<name>IMOS Ocean Currents</name>\n');
% fprintf(fid,'		<Style>\n');
% fprintf(fid,'			<ListStyle>\n');
% fprintf(fid,'				<listItemType>checkHideChildren</listItemType>\n');
% fprintf(fid,'			</ListStyle>\n');
% fprintf(fid,'		</Style>\n');
% fprintf(fid,'	<Link>\n');
% fprintf(fid,'		<href>%s%s.kml</href>\n',altimUrl,cfg.PROJECT);
% fprintf(fid,'		<refreshMode>onInterval</refreshMode>\n');
% fprintf(fid,'		<refreshInterval>300</refreshInterval>\n');
% fprintf(fid,'	</Link>\n');
% fprintf(fid,'</NetworkLink>\n');


%% Plot glider track line
fprintf(fid,'		<Placemark>\n');
fprintf(fid,'			<name>Glider Track</name>\n');
fprintf(fid,'			<styleUrl>#yellowLine</styleUrl>\n');
fprintf(fid,'			<LineString>\n');
fprintf(fid,'				<tessellate>1</tessellate>\n');
fprintf(fid,'				<coordinates>\n');
for i = 1:num_surfacings
    if ~isnan(logs{i, 'GPS_lon'})
        fprintf(fid,' %s,%s,0',num2str(logs{i, 'GPS_lon'}),num2str(logs{i, 'GPS_lat'}));
        %disp([num2str(logs{i, 'GPS_lon'}) ' ' num2str(logs{i, 'GPS_lat'})])
    end
end
fprintf(fid,'               </coordinates>\n');
fprintf(fid,'			</LineString>\n');
fprintf(fid,'		</Placemark>\n');


%% Create markers for all surfacings
fprintf(fid,'			<Folder>\n');
fprintf(fid,'				<name>Surfacings</name>\n');
fprintf(fid,'				<visibility>0</visibility>\n');
fprintf(fid,'				<open>0</open>\n');
dayno = NaN;
for ii = (num_surfacings-1):-1:2
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<TimeStamp>\n');
        fprintf(fid,'  <when>%s</when>\n',datestr(logs{ii, 'current_time'},' yyyy-mm-ddTHH:MMZ')); %yyyy-mm-ddTHH:MMZ
        fprintf(fid,'</TimeStamp>\n');
        %if numSurfacings < 50
            % Print every timestamp
            fprintf(fid,'   <name>%s</name>\n',datestr(logs{ii, 'current_time'},' HH:MM dd.mmm'));
%         else
%             % Print only timestamps at new day
%             if dayno ~= floor(datenum(logs{ii, 'current_time'}))
%                 dayno = floor(datenum(logs{ii, 'current_time'}));
%                 fprintf(fid,'   <name>%s</name>\n',datestr(logs{ii, 'current_time'},'dd.mm HH:MM'));
%             end
%         end
        
        fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
        fprintf(fid,'	<Style>\n');
        fprintf(fid,'		<IconStyle>\n');
        fprintf(fid,'			<scale>0.5</scale>\n');
        fprintf(fid,'			<heading>0</heading>\n');
        fprintf(fid,'			<Icon>\n');
        
        % Use different marker when data is avilable
        file = fullfile(WEBURL,'data','real_time',MISSION,'segments',strrep(char(logs{ii, 'segment_name'}),'-','_'),[char(logs{ii, 'segment_name'}) '-m_depth.png']); 
        localfile = fullfile('/Data/gfi/projects/slocum/data/real_time/',MISSION,'segments',strrep(char(logs{ii, 'segment_name'}),'-','_'),[char(logs{ii, 'segment_name'}) '-m_depth.png']); 
        if exist(localfile,'file')
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
        fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(logs{ii, 'GPS_lon'}),num2str(logs{ii, 'GPS_lat'}));
        fprintf(fid,'	</Point>\n');
        fprintf(fid,'</Placemark>\n');
end
fprintf(fid,'			</Folder>\n');



%% Create markers for all surfacings without timestamps
fprintf(fid,'			<Folder>\n');
fprintf(fid,'				<name>Surfacings (no labels)</name>\n');
fprintf(fid,'				<visibility>1</visibility>\n');
fprintf(fid,'				<open>0</open>\n');
dayno = NaN;
for ii = (num_surfacings-1):-1:2
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<TimeStamp>\n');
        fprintf(fid,'  <when>%s</when>\n',datestr(logs{ii, 'current_time'},'yyyy-mm-ddTHH:MMZ')); %yyyy-mm-ddTHH:MMZ
        fprintf(fid,'</TimeStamp>\n');
        fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
        fprintf(fid,'	<Style>\n');
        fprintf(fid,'		<IconStyle>\n');
        fprintf(fid,'			<scale>0.5</scale>\n');
        fprintf(fid,'			<heading>0</heading>\n');
        fprintf(fid,'			<Icon>\n');
        
        % Use different marker when data is avilable
        if exist(fullfile(PROJECTDIR,'ascii',[char(logs{ii, 'segment_name'}),'_sbd.dat']),'file')
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
        fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(logs{ii, 'GPS_lon'}),num2str(logs{ii, 'GPS_lat'}));
        fprintf(fid,'	</Point>\n');
        fprintf(fid,'</Placemark>\n');
end
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
                vx = logs{ii, 'm_water_vx'}; % srfStruct(ii,1).Sensors.m_water_vx(1);
                vy = logs{ii, 'm_water_vy'}; % srfStruct(ii,1).Sensors.m_water_vy(1);
            catch
                vx = 0;
                vy = 0;
            end
            
            fprintf(fid,'		<Placemark>\n');
            fprintf(fid,'			<visibility>0</visibility>\n');
            fprintf(fid,'           <TimeStamp>\n');
            fprintf(fid,'               <when>%s</when>\n',datestr(logs{ii, 'current_time'},'dd.mmm.yyyy HH:MM'));
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
            
            x1 = logs{ii, 'GPS_lon'}; %srfStruct(ii,1).GPSLocation(2); IS THUIS RIGHT?????
            y1 = logs{ii, 'GPS_lat'}; % srfStruct(ii,1).GPSLocation(1);
            
            sca = 1;
            x2 = x1 + vel*cos(deg2rad(90-brg));
            y2 = y1 + vel*sin(deg2rad(90-brg));
            x3 = x1 + sca*vel*cos(deg2rad((90-brg)-2));
            y3 = y1 + sca*vel*sin(deg2rad((90-brg)-2));
            x4 = x1 + sca*vel*cos(deg2rad((90-brg)+2));
            y4 = y1 + sca*vel*sin(deg2rad((90-brg)+2));
            
            fprintf(fid,' %s,%s,0',num2str(x1),num2str(y1));
            fprintf(fid,' %s,%s,0',num2str(x2),num2str(y2));
            fprintf(fid,' %s,%s,0',num2str(x3),num2str(y3));
            fprintf(fid,' %s,%s,0',num2str(x2),num2str(y2));
            fprintf(fid,' %s,%s,0',num2str(x4),num2str(y4));
            
            fprintf(fid,'\n               </coordinates>\n');
            fprintf(fid,'			</LineString>\n');
            fprintf(fid,'		</Placemark>\n');
    end
    
    fprintf(fid,'			</Folder>\n');
end

fprintf(fid,'</Document>\n');
fprintf(fid,'</kml>\n');

fclose(fid);

