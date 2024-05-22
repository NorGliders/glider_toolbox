function [ logs_table ] = updateActiveGlidersJson(logs_table, segment_struct, json_file, ego_json_file, glider, seagliders_missions)

% updateActiveGlidersJson  Initialize table for processed xbds
% processed_xbds = updateActiveGlidersJson(logs_table, json_file, glider);
%  Syntax:
%    [PROCESSED_XBDS] = updateActiveGlidersJson()

narginchk(6,6);

% If files does not exist create empty structure
if exist(json_file,'file')
    json_code = fileread(json_file);
    json_text = jsondecode(json_code);
else
    json_text = struct('gliders',struct(glider,struct()));
end

ego_json_code = fileread(ego_json_file);
ego_json_text = jsondecode(ego_json_code);
good_fix = ~isnan(logs_table.GPS_lat); % Does this crash if no logs/are no logs possible at this stage?
json_text.gliders.(glider).Ego = ego_json_text;
json_text.gliders.(glider).Waypoints.Latitude = '';
json_text.gliders.(glider).Waypoints.Longitude = '';
json_text.gliders.(glider).Waypoints.Name = '';
json_text.gliders.(glider).Waypoints.Current = '';
json_text.gliders.(glider).TS.Time = logs_table.current_time(good_fix);
json_text.gliders.(glider).TS.Latitude = logs_table.GPS_lat(good_fix);
json_text.gliders.(glider).TS.Longitude = logs_table.GPS_lon(good_fix);
json_text.gliders.(glider).TS.SegmentName = logs_table.segment_name(good_fix);

% Add field with segment info for plotting
json_text.gliders.(glider).segments = segment_struct;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Hack update the SG gliders, just update this every time for now
sg_path = '/Data/gfi/projects/naco/gliderbak/';
if 1
    for i = 1:numel(seagliders_missions)
        sg_mission = seagliders_missions{i};
        sg = sg_mission(1:5);
        sg_target_file = fullfile(sg_path,sg,'targets');
        
        % Read in targets file
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
                    latitude(length(latitude)+1) = deglat;
                    longitude(length(longitude)+1,1) = deglon;
                    names{length(names)+1,1} = name;
                end
            end
        end
        fclose(fid);
        

        
        json_text.gliders.(glider).Waypoints.Latitude = latitude;
        json_text.gliders.(glider).Waypoints.Longitude = longitude;
        json_text.gliders.(glider).Waypoints.Name = names;
        json_text.gliders.(glider).Waypoints.Current = '';
        
        sg_ego_json_file = fullfile(sg_path,sg,'json',[sg_mission '.json']);
        sg_ego_json_code = fileread(sg_ego_json_file);
        sg_ego_json_text = jsondecode(sg_ego_json_code);
        json_text.gliders.(sg).Ego = sg_ego_json_text;
        
        sg_profile_struct = dir(fullfile(sg_path,sg,[sg '*profile.nc'])); % list of all files in directory
        sg_profile_file = char(sg_profile_struct(1).name); % list of all file names
        nc_file = fullfile(sg_path, sg, sg_profile_file);
        
        d1 = loadnc(nc_file);
        json_text.gliders.(sg).TS.Time = datestr(ut2mt(d1.start_time),'yyyy-mm-dd HH:MM:SS');
        json_text.gliders.(sg).TS.Latitude = d1.latitude;
        json_text.gliders.(sg).TS.Longitude = d1.longitude;
        json_text.gliders.(sg).TS.SegmentName = d1.dive_number;
        
        % Update kml file
        sg_srfStruct_to_kml(sg, sg_mission)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


re_json_code = jsonencode(json_text);

fid = fopen(json_file,'wt');
fprintf(fid,'%s',re_json_code);
fclose(fid);





        
        
        
        
        
        
        
        
        
        
        
        
        
        
        