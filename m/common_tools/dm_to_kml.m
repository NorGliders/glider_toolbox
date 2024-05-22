function [] = dm_to_kml(summary, deployment_summary) 


%--------------------------------------------------------------------------
% [] = dm_to_kml((summary, deployment_summary)
% 
% Create kml file for delayed mode data
%--------------------------------------------------------------------------


plot_DAC = 1;
WEBURL = 'https://norgliders.gfi.uib.no'; 
glider_icon = fullfile(WEBURL,'assets','img',[summary.deployment_characteristics.GLIDERPLATFORM '_glider.png']);
DM_dir = '/Data/gfi/projects/slocum/data/delayed'; %project_dir = fullfile(sg_op_res,sg_mission);FE 7.6.23
sn = lower(summary.deployment_characteristics.GLIDERNAME);
MISSION = summary.deployment_characteristics.INTERNALMISSIONID;
outputKmlFilename = fullfile(fileparts(deployment_summary),[MISSION '.kml']);
tracks = summary.tracks;
tracks.time = datenum(tracks.time,'yyyy-mm-dd HH:MM:SS');

disp([getUTC,': Creating kml file for ' sn ', ' MISSION '.kml']);

% Use this colour for glider track
track_col = struct('durin','FFDE3163',...
'dvalin','FFDFFF00',...
'urd','FFFFBF00',...
'verd','FFFF7F50',...
'skuld','FFDE3163',...
'sg560','FF9FE2BF',...
'sg561','FF40E0D0',...
'odin','FF6495ED',...
'sg563','FF8E44AD',... c
'sg564','FFCCCCFF');
col = track_col.(sn);

% Find number of dives
num_surfacings = numel(summary.tracks.lat);
if num_surfacings <= 1
	disp('The NetCDF file for this deployment contains no data. Exiting.');
    return
end

%% Write KML file 
% - Create & write KML file
disp([getUTC,': Creating file: ' outputKmlFilename]);
fid = fopen(outputKmlFilename,'w');

% Start writing KML file
fprintf(fid,'<?xml version="1.0" encoding="UTF-8"?>\n');
fprintf(fid,'<kml xmlns="http://earth.google.com/kml/2.1">\n');
fprintf(fid,'<Document>\n');
fprintf(fid,'	<name>%s</name>\n',MISSION);
fprintf(fid,'\n');

fprintf(fid,'<!-- MAP LOCATION -->\n');
fprintf(fid,'<LookAt>\n');
fprintf(fid,'   <longitude>%s</longitude>\n',num2str(tracks.lon(end)));
fprintf(fid,'	<latitude>%s</latitude>\n',num2str(tracks.lat(end)));
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
fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(tracks.lon(1)),num2str(tracks.lat(1)));
fprintf(fid,'	</Point>\n');
fprintf(fid,'</Placemark>\n');


%% Write Current Location marker & data link
fprintf(fid,'\n');
fprintf(fid,'<!-- Create marker at current glider location -->\n');
fprintf(fid,'<Placemark>\n');
fprintf(fid,'	<name>Last Surfacing: %s</name>\n',datestr(tracks.time(end),'HH:MM dd.mmm.yyyy'));
fprintf(fid,'<description>Last surfacing at %s Z.\n</description>\n',datestr(tracks.time(end),'HH:MM dd.mmm.yyyy'));
fprintf(fid,'	<Snippet maxLines="3"></Snippet>\n');
fprintf(fid,'	<Style>\n');
fprintf(fid,'		<IconStyle>\n');
fprintf(fid,'			<scale>2.0</scale>\n');
fprintf(fid,'			<heading>0</heading>\n');
fprintf(fid,'			<Icon>\n');
fprintf(fid,'				<href>%s</href>\n',glider_icon);
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
fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(tracks.lon(end)),num2str(tracks.lat(end)));
fprintf(fid,'	</Point>\n');
fprintf(fid,'</Placemark>\n');


% %% Write placemark at current waypoint location
% fprintf(fid,'\n');
% fprintf(fid,'<!-- Create waypoint marker -->\n');
% fprintf(fid,'<Placemark>\n');
% fprintf(fid,'	<name>Current Waypoint</name>\n');
% fprintf(fid,'	<visibility>1</visibility>\n');
% fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
% fprintf(fid,'	<Style>\n');
% fprintf(fid,'		<IconStyle>\n');
% %fprintf(fid,'			<color>ff0000ff</color>\n');
% fprintf(fid,'			<scale>0.8</scale>\n');
% fprintf(fid,'			<Icon>\n');
% fprintf(fid,'				<href>%s</href>\n',fullfile(WEBURL,shield_icon));
% fprintf(fid,'			</Icon>\n');
% fprintf(fid,'			<hotSpot x="0.5" y="0" xunits="fraction" yunits="fraction"/>\n');
% fprintf(fid,'		</IconStyle>\n');
% fprintf(fid,'		<LabelStyle>\n');
% fprintf(fid,'			<color>ff0000ff</color>\n');
% fprintf(fid,'			<scale>0.8</scale>\n');
% fprintf(fid,'		</LabelStyle>\n');
% fprintf(fid,'		<BalloonStyle>\n');
% fprintf(fid,'			<text><![CDATA[<iframe src=''%s'' width=600 height=400 frameborder=0 /> ]]></text>\n',WEBURL);
% fprintf(fid,'		</BalloonStyle>\n');
% fprintf(fid,'	</Style>\n');
% fprintf(fid,'	<Point>\n');
% 
% wptLon = waypoints.current.longitude;
% wptLat = waypoints.current.latitude;
% 
% fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(wptLon),num2str(wptLat));
% fprintf(fid,'	</Point>\n');
% fprintf(fid,'</Placemark>\n');

% 
% %% Waypoints
% fprintf(fid,'			<Folder>\n');
% fprintf(fid,'				<name>Waypoints</name>\n');
% fprintf(fid,'				<visibility>1</visibility>\n');
% fprintf(fid,'				<open>0</open>\n');
% 
% % Plot waypoints line
% fprintf(fid,'		<Placemark>\n');
% fprintf(fid,'			<name>Wapoints Line</name>\n');
% fprintf(fid,'			<styleUrl>#whiteLine</styleUrl>\n');
% fprintf(fid,'			<LineString>\n');
% fprintf(fid,'				<tessellate>1</tessellate>\n');
% fprintf(fid,'				<coordinates>\n');
% for i = 1:numel(waypoints.longitude)
%     if ~isnan(waypoints.longitude(i))
%         fprintf(fid,' %s,%s,0',num2str(waypoints.longitude(i)),num2str(waypoints.latitude(i)));
%     end
% end
% fprintf(fid,'               </coordinates>\n');
% fprintf(fid,'			</LineString>\n');
% fprintf(fid,'		</Placemark>\n');
% 
% % Waypoint symbols and labels
% fprintf(fid,'			<Folder>\n');
% fprintf(fid,'				<name>Waypoints</name>\n');
% fprintf(fid,'				<visibility>1</visibility>\n');
% fprintf(fid,'				<open>0</open>\n');
% for i = 1:numel(waypoints.longitude)
%     fprintf(fid,'<Placemark>\n');
%     fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
%     fprintf(fid,'	<Style>\n');
%     fprintf(fid,'		<IconStyle>\n');
%     fprintf(fid,'			<scale>0.7</scale>\n');
%     fprintf(fid,'			<heading>0</heading>\n');
%     fprintf(fid,'			<Icon>\n');
%     fprintf(fid,'				<href>%s</href>\n',fullfile(WEBURL,waypoint_icon));
%     % fprintf(fid,'				<href>http://maps.google.com/mapfiles/kml/pal4/icon57.png</href>\n'); %icon48
%     fprintf(fid,'			</Icon>\n');
%     fprintf(fid,'		</IconStyle>\n');
%     fprintf(fid,'		<LabelStyle>\n');
%     fprintf(fid,'			<scale>0.60</scale>\n');
%     fprintf(fid,'		</LabelStyle>\n');
%     fprintf(fid,'		<BalloonStyle>\n');
%     fprintf(fid,'			<text><![CDATA[<iframe width=940 height=820 frameborder=0 /> ]]>%s</text>\n',waypoints.name{i});
%     fprintf(fid,'		</BalloonStyle>\n');
%     fprintf(fid,'	</Style>\n');
%     fprintf(fid,'	<Point>\n');
%     fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(waypoints.longitude(i)),num2str(waypoints.latitude(i)));
%     fprintf(fid,'	</Point>\n');
%     fprintf(fid,'</Placemark>\n');
% end
% fprintf(fid,'			</Folder>\n');
% 
% % Waypoint symbols no labels
% fprintf(fid,'			<Folder>\n');
% fprintf(fid,'				<name>Waypoints Labels</name>\n');
% fprintf(fid,'				<visibility>1</visibility>\n');
% fprintf(fid,'				<open>0</open>\n');
% for i = 1:numel(waypoints.longitude)
%     fprintf(fid,'<Placemark>\n');
%     fprintf(fid,'	   <name>%s</name>\n',waypoints.name{i});
%     fprintf(fid,'	<Snippet maxLines="0"></Snippet>\n');
%     fprintf(fid,'	<Style>\n');
%     fprintf(fid,'		<IconStyle>\n');
%     fprintf(fid,'			<scale>0.7</scale>\n');
%     fprintf(fid,'			<heading>0</heading>\n');
%     fprintf(fid,'			<Icon>\n');
%     fprintf(fid,'				<href>%s</href>\n',fullfile(WEBURL,waypoint_icon));
%     % fprintf(fid,'				<href>http://maps.google.com/mapfiles/kml/pal4/icon57.png</href>\n'); %icon48
%     fprintf(fid,'			</Icon>\n');
%     fprintf(fid,'		</IconStyle>\n');
%     fprintf(fid,'		<LabelStyle>\n');
%     fprintf(fid,'			<scale>0.60</scale>\n');
%     fprintf(fid,'		</LabelStyle>\n');
%     fprintf(fid,'		<BalloonStyle>\n');
%     fprintf(fid,'			<text><![CDATA[<iframe width=940 height=820 frameborder=0 /> ]]>%s</text>\n',waypoints.name{i});
%     fprintf(fid,'		</BalloonStyle>\n');
%     fprintf(fid,'	</Style>\n');
%     fprintf(fid,'	<Point>\n');
%     fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(waypoints.longitude(i)),num2str(waypoints.latitude(i)));
%     fprintf(fid,'	</Point>\n');
%     fprintf(fid,'</Placemark>\n');
% end
% fprintf(fid,'			</Folder>\n');
% 
% fprintf(fid,'			</Folder>\n');

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
    if ~isnan(tracks.lon)
        fprintf(fid,' %s,%s,0',num2str(tracks.lon(i)),num2str(tracks.lat(i)));
    end
end
% NOTE: We are plotting the points from the start of every dive, add the
% end point of the final dive to connect to the current poisiton icon. We
% may want to edit configuration to show surface drift - althoug unsure if
% gps is correctted to reflect drift.
fprintf(fid,' %s,%s,0',num2str(tracks.lon(end)),num2str(tracks.lat(end)));
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
        fprintf(fid,'  <when>%s</when>\n',datestr(tracks.time(ii),'yyyy.mm.ddTHH:MMZ')); %yyyy-mm-ddTHH:MMZ
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
        fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(tracks.lon(ii)),num2str(tracks.lat(ii)));
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
        fprintf(fid,'  <when>%s</when>\n',datestr(tracks.time(ii),'yyyy.mm.ddTHH:MMZ')); %yyyy-mm-ddTHH:MMZ
        fprintf(fid,'</TimeStamp>\n');
        fprintf(fid,'   <name>%s</name>\n',datestr(tracks.time(ii),'HH:MM dd.mmm'));
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
        fprintf(fid,'      <coordinates>%s,%s,0</coordinates>\n',num2str(tracks.lon(ii)),num2str(tracks.lat(ii)));
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
                vx = tracks.DACu(ii); % srfStruct(ii,1).Sensors.m_water_vx(1);
                vy = tracks.DACv(ii); % srfStruct(ii,1).Sensors.m_water_vy(1);
            catch
                vx = 0;
                vy = 0;
            end
            
            fprintf(fid,'		<Placemark>\n');
            fprintf(fid,'			<visibility>0</visibility>\n');
            fprintf(fid,'           <TimeStamp>\n');
            fprintf(fid,'               <when>%s</when>\n',datestr(tracks.time(ii),'dd.mmm.yyyy HH:MM'));
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
            x1 = tracks.lon(ii); %srfStruct(ii,1).GPSLocation(2); IS THUIS RIGHT?????
            y1 = tracks.lat(ii); % srfStruct(ii,1).GPSLocation(1);
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
