function read_slocum_log(cfg,fileName)
%--------------------------------------------------------------------------
% read_slocum_log(cfg,fileName)
% %read_slocum_log(cfg.GLIDER,LOG_DIR,OUT_DIR,logFilesToProcess{i,1},cfg.FIRMWARE_VER);
% Extract relevant information out of Dockserver logfiles (Glider-term
% recorded seesion.
%
% NIWA Slocum toolbox
%
% History:
% -2014             ANFOG
% 2015-Jun-17 FE    Adapted for the NIWA Slocum toolbox
%--------------------------------------------------------------------------

%% --- Comment out if not debugging ---
% cfg = parse_config_file('V:\Glider\process1\betty.cfg');
% fileName = 'betty_freewave_20180530T192247.log';

%% --- Setup ---
glider = cfg.GLIDER;
dataInDir = fullfile(cfg.PROJECT_DIR,'logs');
dataOutDir = cfg.PROJECT_DIR;
jsonDir = fullfile(cfg.PROJECT_DIR,'json');
fid = fopen(fullfile(dataInDir,fileName));


%% --- Start reading through file ---
fileInfo = dir(fullfile(dataInDir,fileName));
try
    if fileInfo.bytes < 1500
        disp([repmat(' ',1,23) 'Skipping file ',fileName,' --> No Data...'])
        fclose(fid);
        return
    else
        screen_print('log',['Reading: ' fileName '...'])
        while ~feof(fid)
            tline = fgetl(fid);
            
            %% Glider Mission Surfacing
            % Looks for phrase '<glidername> at surface'. If this isn't
            % present its either not in a mission or is calling back
            if ~isempty(strfind(tline,['Glider ' glider ' at surface']))
                
                % Because...
                tline = fgetl(fid);
                srfInfo.Because = strtrim(tline(strfind(tline,':')+1:end));
                
                % MissionName...
                tline = fgetl(fid);
                srfInfo.MissionName = strtrim(tline(13:strfind(tline,'MissionNum:')-1));
                srfInfo.SegmentName = strtrim(tline(strfind(tline,'MissionNum:')+11:strfind(tline,'(')-1));
                srfInfo.SegmentName(strfind(srfInfo.SegmentName,'-'))='_';
                srfInfo.SegmentNum = strtrim(tline(strfind(tline,'(')+1:strfind(tline,')')-1));
                
                % Vehicle Name...
                tline = fgetl(fid);
                srfInfo.VehicleName = strtrim(tline(14:end));
                
                % Mission data...
                srfInfo.Project = cfg.PROJECT;
                srfInfo.Mission = cfg.MISSION;
                
                % Current Time...
                tline = fgetl(fid);
                CurrTimeStr = strtrim(tline(11:strfind(tline,'MT:')-1));
                srfInfo.CurrentTimeNum = datenum(CurrTimeStr, 'ddd mmm dd HH:MM:SS yyyy');
                srfInfo.CurrentTime = datestr(srfInfo.CurrentTimeNum);
                srfInfo.MissionTime = str2num(tline(strfind(tline,'MT:')+3:end));
                srfInfo.MissionStart = cfg.DEPLOY_DATE;
                
                % Read positions
                j = 0;
                for i = 1:4
                    tline = fgetl(fid);
                    j = j+1;
                    PosName{j,1} = strtrim(tline(1:strfind(tline,':')-1));
                    PosLat(j,1)  = dm2dd(str2num(tline(strfind(tline,':')+1:strfind(tline,'N')-1)));
                    PosLatNMEA{j}  = tline(strfind(tline,':')+1:strfind(tline,'N'));
                    PosLon(j,1)  = dm2dd(str2num(tline(strfind(tline,'N')+1:strfind(tline,'E')-1)));
                    PosLonNMEA{j}  = tline(strfind(tline,'N')+1:strfind(tline,'E'));
                    PosAge(j,1)  = str2num(tline(strfind(tline,'measured')+8:strfind(tline,'secs')-1));
                end
                clear('j');
                
                % Write position info into structure
                for i=1:length(PosName)
                    ind = strfind(PosName{i,1},' ');
                    PosName{i,1}(ind) = [];
                    evalStr = ['srfInfo.',PosName{i,1},'=[PosLat(',num2str(i),',1),PosLon(',num2str(i),',1),PosAge(',num2str(i),',1)];'];
                    eval(evalStr);
                end
                
                % Set send UDP feed to on
                % Create txt file to send
                if isfield(srfInfo,'GPSLocation') && ~isempty(srfInfo.GPSLocation)
                    create_RMC(srfInfo,PosLatNMEA,PosLonNMEA,dataOutDir,cfg.APP_DIR);
                end
                
                % Read sensors
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
                    SensorName{j,1}= tline(strfind(tline,':')+1:strfind(tline,'(')-1);
                    
                    a = strfind(tline,' ');
                    b = strfind(tline,'=');
                    c = a(min(find(a>b)));
                    SensorVal(j,1) = str2num(tline(b+1:c));
                    
                    d = a(find(a==max(a))-2);
                    SensorAge(j,1) = str2num(tline(d+1:strfind(tline,'secs ago')-2));
                    
                    % Get rid of stale data
                    if SensorAge(j,1)== 1.0e+308
                        SensorAge(j,1) = NaN;
                        SensorVal(j,1) = NaN;
                    end
                    
                    tline = fgetl(fid);
                    clear('a','b','c','d');
                end
                clear('j');
                
                % Hack remove autoballast FE
                if ismember(SensorName,'c_autoballast_state')
                    loc = ismember(SensorName,'c_autoballast_state');
                    SensorName(loc)=[];
                    SensorAge(loc)=[];
                    SensorVal(loc)=[];
                end
                
                % Write sensor info into structure
                for i=1:length(SensorName)
                    evalStr = ['srfInfo.Sensors.',SensorName{i,1},'=[SensorVal(',num2str(i),',1),SensorAge(',num2str(i),',1)];'];
                    eval(evalStr);
                end
                
                % Device info
                srfInfo.DeviceStr = tline;
                
                % Abort history
                srfInfo.AbortStr = fgetl(fid);
                
                nextline = fgetl(fid);
                strfind(nextline,'ABORT HISTORY:');
                if strfind(nextline,'ABORT HISTORY:')==1
                    if FirmwareVer >= 7.5
                        % Skip abort history lines
                        for i=1:5
                            % UPDATETD from 4 to 5 for firmware version 7.5
                            % ---------------------------------------------------------
                            % ABORT HISTORY: total since reset: 8
                            % ABORT HISTORY: last abort cause: MS_ABORT_NO_HEADING_MEASUREMENT
                            % ABORT HISTORY: last abort details:
                            % ABORT HISTORY: last abort time: 2011-07-02T11:27:05
                            % ABORT HISTORY: last abort segment: unit209-2011-182-4-0 (0078.0000)
                            % ABORT HISTORY: last abort mission: IMOSGO20.MI
                            % ---------------------------------------------------------
                            skip = fgetl(fid);
                        end
                    else
                        for i=1:4             %
                            % Skip 4 lines for firmware prior to version 7.5
                            % ---------------------------------------------------------
                            % ABORT HISTORY: total since reset: 1
                            % ABORT HISTORY: last abort cause: MS_NOINPUT
                            % ABORT HISTORY: last abort time: 2011-07-21T04:48:30
                            % ABORT HISTORY: last abort segment: unit100-2011-201-8-2 (0070.0002)
                            % ABORT HISTORY: last abort mission: AUV_GO20.MI
                            % ---------------------------------------------------------
                            skip = fgetl(fid);
                        end
                    end
                end
                
                % Skip instruction section
                for i=1:12
                    skip = fgetl(fid);
                end
                
                % Read waypoint infornmation
                wptStr = fgetl(fid);
                
                WaypointLatLon = str2num(wptStr(strfind(wptStr,'(')+1:strfind(wptStr,')')-1));
                srfInfo.Waypoint.Lat = dm2dd(WaypointLatLon(1));
                srfInfo.Waypoint.Lon = dm2dd(WaypointLatLon(2));
                srfInfo.Waypoint.Rng    = str2num(wptStr(strfind(wptStr,'Range:')+6:strfind(wptStr,'Bearing:')-4)); % Waypoint range in m
                srfInfo.Waypoint.Brg    = str2num(wptStr(strfind(wptStr,'Bearing:')+8:strfind(wptStr,'Age:')-6));   % Waypoint bearing in degrees
                srfInfo.Waypoint.AgeStr = strtrim(wptStr(strfind(wptStr,'Age:')+4:end));                            % Waypoint age string
                
                % Close log file
                fclose(fid);
                
                % Add info to SRF_INFO_STRUCT file
                if srfInfo.GPSLocation(1) < 600000
                    if exist(fullfile(dataOutDir,[glider,'_srfStruct.mat']),'file')
                        disp([repmat(' ',1,23) 'Added data to file SRF_INFO_STRUCT.mat']);
                        load(fullfile(dataOutDir,[glider,'_srfStruct.mat']));
                        srfStruct(length(srfStruct)+1,1)=srfInfo;
                        save(fullfile(dataOutDir,[glider,'_srfStruct.mat']),'srfStruct');
                        clear('dive','diveStruct');
                    else
                        disp([repmat(' ',1,23) 'Created new file SRF_INFO_STRUCT.mat']);
                        srfStruct(1,1)=srfInfo;
                        save(fullfile(dataOutDir,[glider,'_srfStruct.mat']),'srfStruct');
                        clear('dive','diveStruct');
                    end
                else
                    % SKIP "NO-POSITION" surfacings
                    disp([repmat(' ',1,23) 'No valid GPS location, data not added to structure... ']);
                end
                
                % SUMMARY DATA FILE FOR WEB DISPLAY Create segment.mat
                % Check if segment directory exists & if not, create
                segDir = fullfile(dataOutDir,'segments',srfInfo.SegmentName);
                if ~exist(segDir,'dir')
                    disp([repmat(' ',1,23) 'Creating segment directory: ',segDir]);
                    mkdir(segDir);
                    fid = fopen(fullfile(segDir,'processing.txt'),'w');
                    fprintf(fid, '%s %s Created segment directory\n', mfilename, datestr(now));
                    fprintf(fid, '%s %s seg_name = %s\n', mfilename, datestr(now), srfInfo.SegmentName);
                    fprintf(fid, '%s %s Created new segment.mat file', mfilename, datestr(now));
                    fclose(fid);
                end
                
                % Create segment .mat file
                disp([repmat(' ',1,23) 'Creating summary data .mat file for web display']);
                % fid = fopen(fullfile(segDir,'segment.txt'),'w');
                
                segmentStruct.segmentName = srfInfo.SegmentName;
                segmentStruct.segmentNum = srfInfo.SegmentNum;
                segmentStruct.vehicleName = srfInfo.VehicleName;
                tmp = strfind(srfInfo.Because,'['); segmentStruct.because = srfInfo.Because(1:tmp(1)-2);
                segmentStruct.currentTimeNum = ut2mt(srfInfo.CurrentTimeNum);
                segmentStruct.currentTime = srfInfo.CurrentTime;
                segmentStruct.latEnd = srfInfo.GPSLocation(1);
                segmentStruct.lonEnd = srfInfo.GPSLocation(2);
                
                % Write sensor information to summary file
                for i = 1:length(SensorName)
                    eval(['segmentStruct.' SensorName{i} ' = SensorVal(' num2str(i) ');']);
                end
                
                % Write waypoint information to summary file
                segmentStruct.waypoint_lat = srfInfo.Waypoint.Lat;
                segmentStruct.waypoint_lon =  srfInfo.Waypoint.Lon;
                segmentStruct.waypoint_range =  srfInfo.Waypoint.Rng;
                segmentStruct.waypoint_brg =  srfInfo.Waypoint.Brg;
                
                % Save segmentStruct to .mat
                save(fullfile(segDir,[srfInfo.SegmentName '.mat']), '-struct', 'segmentStruct');
                save(fullfile(dataOutDir,'Segment.mat'), '-struct', 'segmentStruct');
                
                % Save data to json object -moved to end of script
                savejson('',srfStruct(end),'FileName',fullfile(segDir,'segment.json'));

                
                % Copy current log file to process directory
                disp(['***Copying ' fullfile(dataInDir,fileName) ' to ' fullfile(dataOutDir,[glider '.log'])])
                copyfile(fullfile(dataInDir,fileName),fullfile(dataOutDir,[glider '.log']))
                
                % Send copy to DATA_DIR
                % copyfile(fullfile(segDir,'segment.txt'),dataOutDir)
                disp([repmat(' ',1,23) 'Creating new segment.mat and segment.json'])
                disp(' ')
                disp(srfInfo)
                
                % Once one info text has been read exit program...
%                 fclose(fid)
                return
            end
            if ~ischar(tline), break, end
        end
    end
catch ME
    disp(['2. Error occurred while processing: ',fileName]);
    disp([ME.message ' @ line no.' num2str(ME.stack(1).line)])
    disp('')
end


%% --- No mission surfacings found - look for connection info ---
% This occurs after glider has surfaced already and is calling back for
% some reason e.g. cal dropped out, callback 30
% Add data to SRF_INFO_STRUCT file but do not write new segment.txt file
frewind(fid);
try
    disp([repmat(' ',1,23) 'NO MISSION SURFACINGS FOUND... look for connection info'])
    while ~feof(fid)
        tline = fgetl(fid);
        
        % --- Case#1: Glider connects to DS (Not "Mission Surfacing")
        if strncmpi(tline,'Vehicle Name',12)
            
            disp([repmat(' ',1,23) 'Found surfacing...']);
            
            % Because...
            srfInfo.Because = '';
            
            % MissionName...
            srfInfo.MissionName = '';
            srfInfo.SegmentName = '';
            srfInfo.SegmentNum = '';
            
            % Vehicle Name...
            srfInfo.VehicleName = strtrim(tline(14:end));
            
            % -----------------------------------------------------------------
            % Mission data...
            srfInfo.Project = cfg.PROJECT;
            srfInfo.Mission = cfg.MISSION;
            
            % -----------------------------------------------------------------
            % Current Time...
            tline = fgetl(fid);
            CurrTimeStr = strtrim(tline(11:strfind(tline,'MT:')-1));
            srfInfo.CurrentTimeNum = datenum(CurrTimeStr, 'ddd mmm dd HH:MM:SS yyyy');
            srfInfo.CurrentTime = datestr(srfInfo.CurrentTimeNum);
            srfInfo.MissionTime = str2num(tline(strfind(tline,'MT:')+3:end));
            srfInfo.MissionStart = cfg.DEPLOY_DATE;
            
            % -----------------------------------------------------------------
            % Read position info from text file
            j=0;
            for i=1:4
                tline = fgetl(fid);
                j=j+1;
                PosName{j,1} = strtrim(tline(1:strfind(tline,':')-1));
                PosLat(j,1)  = dm2dd(str2num(tline(strfind(tline,':')+1:strfind(tline,'N')-1)));
                PosLatNMEA{j}  = tline(strfind(tline,':')+1:strfind(tline,'N'));
                PosLon(j,1)  = dm2dd(str2num(tline(strfind(tline,'N')+1:strfind(tline,'E')-1)));
                PosLonNMEA{j}  = tline(strfind(tline,'N')+1:strfind(tline,'E'));
                PosAge(j,1)  = str2num(tline(strfind(tline,'measured')+8:strfind(tline,'secs')-1));
            end
            clear('j');
            
            % -----------------------------------------------------------------
            % Write position info into structure
            for i=1:length(PosName)
                ind = strfind(PosName{i,1},' ');
                PosName{i,1}(ind) = [];
                evalStr = ['srfInfo.',PosName{i,1},'=[PosLat(',num2str(i),',1),PosLon(',num2str(i),',1),PosAge(',num2str(i),',1)];'];
                eval(evalStr);
            end
            
            % Set send UDP feed to on
            % Create txt file to send
            if isfield(srfInfo,'GPSLocation') && ~isempty(srfInfo.GPSLocation)
                create_RMC(srfInfo,PosLatNMEA,PosLonNMEA,dataOutDir,cfg.APP_DIR);
            end
            
            % -----------------------------------------------------------------
            % Read sensors info from text file
            j=0;
            tline = fgetl(fid);
            while strncmpi(tline,'   sensor',9)
                
                % Stop if incomplete line experienced
                if length(tline)<strfind(tline,'secs ago')
                    fclose(fid);
                    return
                end
                
                j=j+1;
                SensorName{j,1}= tline(strfind(tline,':')+1:strfind(tline,'(')-1);
                
                a = strfind(tline,' ');
                b = strfind(tline,'=');
                c = a(min(find(a>b)));
                
                SensorVal(j,1) = str2num(tline(b+1:c));
                
                d = a(find(a==max(a))-2);
                
                SensorAge(j,1) = str2num(tline(d+1:strfind(tline,'secs ago')-2));
                
                % get rid of stale data
                if SensorAge(j,1)== 1.0e+308
                    SensorAge(j,1) = NaN;
                    SensorVal(j,1) = NaN;
                end
                
                tline = fgetl(fid);
                clear('a','b','c','d');
            end
            clear('j')
            
            % hack remove autoballast
            if ismember(SensorName,'c_autoballast_state')
                loc = ismember(SensorName,'c_autoballast_state');
                SensorName(loc)=[];
                SensorAge(loc)=[];
                SensorVal(loc)=[];
            end
            
            % Write sensor info into structure
            for i=1:length(SensorName)
                evalStr = ['srfInfo.Sensors.',SensorName{i,1},'=[SensorVal(',num2str(i),',1),SensorAge(',num2str(i),',1)];'];
                eval(evalStr);
            end
            
            % Device info
            srfInfo.DeviceStr = '';
            % Abort history
            srfInfo.AbortStr = '';
            % Read waypoint infornmation
            srfInfo.Waypoint.Lat = NaN;
            srfInfo.Waypoint.Lon = NaN;
            srfInfo.Waypoint.Rng    = NaN;
            srfInfo.Waypoint.Brg    = NaN;
            srfInfo.Waypoint.AgeStr = '';
            
            if srfInfo.GPSLocation(1) < 600000
                
                % Add info to SRF_INFO_STRUCT file
                if exist(fullfile(dataOutDir,[glider,'_srfStruct.mat']),'file')
                    disp([repmat(' ',1,23) 'Added data to SRF_INFO_STRUCT file...']);
                    disp(srfInfo)
                    load(fullfile(dataOutDir,[glider,'_srfStruct.mat']));
                    srfStruct(length(srfStruct)+1,1)=srfInfo;
                    save(fullfile(dataOutDir,[glider,'_srfStruct.mat']),'srfStruct');
                    clear('dive','diveStruct');
                else
                    disp([repmat(' ',1,23) 'Created new data file...']);
                    srfStruct(1,1) = srfInfo;
                    save(fullfile(dataOutDir,[glider,'_srfStruct.mat']),'srfStruct');
                    disp([repmat(' ',1,23) 'Added data to SRF_INFO_STRUCT file...']);
                    disp(srfInfo)
                    clear 'dive' 'diveStruct'
                end
                
            else
                % SKIP "NO-POSITION" surfacings
            end
            
            % Once one info txt read exit program...
            fclose(fid);
            return
        end
        if ~ischar(tline), break, end
    end
catch ME
    disp(['2. Error occurred while processing: ',fileName]);
    disp([ME.message ' @ line no.' num2str(ME.stack(1).line)])
    disp('')
    fclose(fid);
end

%     end
%     disp([repmat(' ',1,23) 'Did not find surfacing, or connection info']);
%     fclose(fid);
% catch
%     disp([repmat(' ',1,23) 'ERROR OCCURED while processing (connection info): ',fileName]);
% end

function create_RMC(srfInfoA,PosLatNMEAA,PosLonNMEAA,dataOutDirA,pyPath)
% Create NMEA string RMC
% $GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A
% Where:
%      RMC          Recommended Minimum sentence C
%      123519       Fix taken at 12:35:19 UTC
%      A            Status A=active or V=Void.
%      4807.038,N   Latitude 48 deg 07.038' N
%      01131.000,E  Longitude 11 deg 31.000' E
%      022.4        Speed over the ground in knots
%      084.4        Track angle in degrees True
%      230394       Date - 23rd of March 1994
%      003.1,W      Magnetic Variation
%      *6A          The checksum data, always begins with *
try
    RMC = ['$GPRMC,' datestr(srfInfoA.CurrentTimeNum,'HHMMSS.FFF') ',A,' PosLatNMEAA{4}(3:end-2) ',S,' PosLonNMEAA{4}(2:end-2) ',' PosLonNMEAA{4}(end) ',0,0,' datestr(srfInfoA.CurrentTimeNum,'DDMMYY') ',003.1,W*6A'];
    %RMC = ['$GPRMC,' datestr(srfInfoA.CurrentTimeNum,'HHMMSS') ',A,' PosLatNMEAA{4}(3:end-2) ',' PosLatNMEAA{4}(end) ',' PosLonNMEAA{4}(2:end-2) ',' PosLonNMEAA{4}(end) ',0,0,' datestr(srfInfoA.CurrentTimeNum,'DDMMYY') ',003.1,W*6A'];
    fileID = fopen(fullfile(dataOutDirA,'UDP_glider_position.txt'),'w');
    fprintf(fileID,RMC,'\n');
    fclose(fileID);
    % Run py script to send toe port
    [status, result] = dos(['python ' pyPath '\DAS_send_UDP_GLIDER.py']);
    if ~status
        screen_print('blank','Sending new surface position to UDP')
        screen_print('blank',RMC)
    else
        screen_print('blank','Failed sending new surface position to UDP')
    end
catch
    screen_print('blank','Failed sending new surface position to UDP')
end