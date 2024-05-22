function json_summary_main_glider_processing_dt(deployment_table, data_processed, figure_dir, deployment_summary, all_deployments_summary)

%% Make plots to find start and stop times
if 1 %first_run
    % Find the index of the CTD pressure for the first and last dives to a certain depth
    start_depth_limit = 50;
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
%             disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(n)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(n))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(n))) '   loc (before first loc):' num2str(n)])
        end
        disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(loc)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(loc))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(loc))) '   loc:' num2str(loc)])
        if ind == numel(doubled_DAC)
            n = loc+1;
            disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(n)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(n))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(n))) '   loc (after last loc, currently used value):' num2str(n)])
%             n = loc+2;
%             disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(n)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(n))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(n))) '   loc (after last loc):' num2str(n)])
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
        data_processed.profile_index(index_DACu(doubled_DAC)) == get_unique_profile(ind);
        
        %unique_profiles = unique(get_profile)
        %[C,IA,IC] = unique(get_profile)
        for ind = 1:numel(doubled_DAC)
            loc = doubled_DAC(ind);
            %plot(fh,datetime(ut2mt(data_processed.time(index_DACu(loc))),'ConvertFrom','datenum'),[0],'ko','MarkerFaceColor','k');
            if ind == 1
                n = loc -1;
%                 disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(n)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(n))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(n))) '   loc (before first loc):' num2str(n)])
            end
%             disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(loc)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(loc))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(loc))) '   loc:' num2str(loc)])
            if ind == numel(doubled_DAC)
                n = loc+1;
%                 disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(n)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(n))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(n))) '   loc (after last loc, currently used value):' num2str(n)])
%                 n = loc+2;
%                 disp(['Time:' datestr(ut2mt(data_processed.time(index_DACu(n)))) '   Profile no:' num2str(data_processed.profile_index(index_DACu(n))) '   DACu:' num2str(data_processed.water_velocity_eastward(index_DACu(n))) '   loc (after last loc):' num2str(n)])
            end
            
        end
        
    end
end


profile_index_of_DAC = data_processed.profile_index(index_DACu);
tracks.DACu = zeros(size(midpoint_of_segments))*nan;
tracks.DACv = zeros(size(midpoint_of_segments))*nan;
for ind = 1:numel(midpoint_of_segments)
    %disp(num2str(midpoint_of_segments(ind)))
    loc = find(ut2mt(data_processed.time(index_DACu)) > midpoint_of_segments(ind),1,'first');
    if isempty(loc)
        disp(['No DAC value founds found after mid-segment time: ' datestr(midpoint_of_segments(ind))])
        tracks.DACu(ind) = NaN;
        tracks.DACv(ind) = NaN;
    else
        tracks.DACu(ind) = data_processed.water_velocity_eastward(index_DACu(loc));
        tracks.DACv(ind) = data_processed.water_velocity_northward(index_DACu(loc));
    end
end

find_nans = isnan(tracks.DACu);
tracks.DACu(find_nans) = [];
tracks.DACv(find_nans) = [];
tracks.time(find_nans) = [];

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

%kml
dm_to_kml(summary, deployment_summary) 







