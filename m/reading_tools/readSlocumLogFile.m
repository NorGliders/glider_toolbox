function [ surf_data ] = readSlocumLogFile(file, glider)
% readSlocumLogFile  Read in a surface dialog from a slocum log file
% surf_data = readSlocumLogFile(file, glider);
%  Syntax:
%    [ data ] = readSlocumLogFile(x, y)

narginchk(2,2);
fid = fopen(file);
[~, filename, file_ext] = fileparts(file);
filename = [filename file_ext];
file_info = dir(file);
surf_data = struct();
surf_data.log_file = string(filename);
surf_data.bytes = file_info.bytes;
surf_data.verified = 1;
surf_data.because = ''; surf_data.mission_name = ''; surf_data.segment_name = ''; surf_data.segment_num = ''; surf_data.vehicle_name = ''; surf_data.device_str = ''; surf_data.abort_str = '';
surf_data.current_time = ''; surf_data.GPS_time = '';

%% --- Start reading through file ---
try
    disp(['Reading: <a href="' file '">' filename '</a>'])
    while ~feof(fid)
        tline = fgetl(fid);
        
        %% Glider Mission Surfacing
        % Looks for phrase '<glidername> at surface'. If this isn't
        % present its either not in a mission or is calling back
        if contains(tline,['Glider ' glider ' at surface'])
            
            % Because...
            tline = fgetl(fid);
            if numel(tline) < 5
                ME = MException('MyComponent:noSuchVariable', ...
                    'No Because str: ',tline);
                throw(ME)
            end
            surf_data.because = string(strtrim(tline(strfind(tline,':')+1:end)));
            
            % MissionName...
            tline = fgetl(fid);
            if numel(tline) < 52
                ME = MException('MyComponent:noSuchVariable', ...
                    'No Mission str: ',tline);
                throw(ME)
            end
            surf_data.mission_name = string(strtrim(tline(13:strfind(tline,'MissionNum:')-1)));
            surf_data.segment_name = string(strtrim(tline(strfind(tline,'MissionNum:')+11:strfind(tline,'(')-1)));
            surf_data.segment_num = strtrim(strrep(tline(strfind(tline,'(')+1:strfind(tline,')')-1),'.',''));
            
            % Vehicle Name...
            tline = fgetl(fid);
            if numel(tline) < 2
                ME = MException('MyComponent:noSuchVariable', ...
                    'No Vehicle name: ',tline);
                throw(ME)
            end
            surf_data.vehicle_name = strtrim(tline(14:end));
            
            % Current Time...
            tline = fgetl(fid);
            current_time_str = strtrim(tline(11:strfind(tline,'MT:')-1));
            if numel(current_time_str) < numel('ddd mmm dd HH:MM:SS yyyy')
                ME = MException('MyComponent:noSuchVariable', ...
                    'Date string corrupted: ',current_time_str);
                throw(ME)
            end
            current_time_num = datenum(current_time_str, 'ddd mmm dd HH:MM:SS yyyy');
            surf_data.current_time = string(datestr(current_time_num, 'yyyy-mm-dd HH:MM:SS')); 
            mt = str2num(tline(strfind(tline,'MT:')+3:end));
            if ~isempty(mt) && isnumeric(mt)
                surf_data.mission_time = str2num(tline(strfind(tline,'MT:')+3:end));
            else
                surf_data.mission_time = NaN;
            end
                    
            
            % Read positions
            tline = fgetl(fid);
            if numel(tline) < 60
                ME = MException('MyComponent:noSuchVariable', ...
                    'No DR Str: ',tline);
                throw(ME)
            end
            surf_data.DR_lat = nmea2deg(str2num(tline(strfind(tline,':')+1:strfind(tline,'N')-1)));
            surf_data.DR_lon = nmea2deg(str2num(tline(strfind(tline,'N')+1:strfind(tline,'E')-1)));
            tline = fgetl(fid);
            tline = fgetl(fid);
            tline = fgetl(fid);
            if numel(tline) < 60 || ~contains(tline, 'GPS Location:')
                ME = MException('MyComponent:noSuchVariable', ...
                    'No GPS Str: ',tline);
                throw(ME)
            end
            
            
            if ~isempty(nmea2deg(str2num(tline(strfind(tline,':')+1:strfind(tline,'N')-1))))
                surf_data.GPS_lat = nmea2deg(str2num(tline(strfind(tline,':')+1:strfind(tline,'N')-1)));
            else surf_data.GPS_lat = [];
            end
            if ~isempty(nmea2deg(str2num(tline(strfind(tline,'N')+1:strfind(tline,'E')-1))))
                surf_data.GPS_lon = nmea2deg(str2num(tline(strfind(tline,'N')+1:strfind(tline,'E')-1)));
            else surf_data.GPS_lon = [];
            end
            if ~isempty(string(datestr(current_time_num - str2num(tline(strfind(tline,'measured')+8:strfind(tline,'se')-1)),'yyyy-mm-dd HH:MM:SS')))
                surf_data.GPS_time = string(datestr(current_time_num - str2num(tline(strfind(tline,'measured')+8:strfind(tline,'se')-1)),'yyyy-mm-dd HH:MM:SS'));
            else surf_data.GPS_time = ''; 
            end
            
            % Read all sensors
            j=0;
            tline = fgetl(fid);
            while strncmpi(tline,'   sensor',9)
                % Stop if incomplete line experienced
                if length(tline)<strfind(tline,':')
                    fclose(fid);
                    return
                end
                if length(tline)<strfind(tline,'=')+10
                    fclose(fid);
                    return
                end
                if length(tline)<strfind(tline,'secs ago')
                    fclose(fid);
                    return
                end
                
                j = j+1;
                sensor_name{j,1}= tline(strfind(tline,':')+1:strfind(tline,'(')-1);
                
                a = strfind(tline,' ');
                b = strfind(tline,'=');
                c = a(a>b);
                c = c(1);
                sensor_val(j,1) = str2num(tline(b+1:c));
                clear a b c d
                tline = fgetl(fid);
            end
            
            % Write sensor info into structure
            for i=1:length(sensor_name)
                % Convert current waypoints to decimal degrees
                if strcmp(sensor_name{i},'c_wpt_lat')
                    sensor_val(i,1) = nmea2deg(sensor_val(i,1));
                end
                if strcmp(sensor_name{i},'c_wpt_lon')
                    sensor_val(i,1) = nmea2deg(sensor_val(i,1));
                end
                surf_data.(sensor_name{i,1}) = sensor_val(i,1);
            end
            
            % Device info
            surf_data.device_str = string(tline);
            
            % Abort history
            surf_data.abort_str = string(fgetl(fid));
            
            % Close log file
            fclose(fid);
            return
        end
    end
catch ME
    disp(['Error occurred while processing: ',mfilename]);
    disp([ME.message ' @ line no.' num2str(ME.stack(1).line)])
    disp(surf_data)
    fclose(fid);
end