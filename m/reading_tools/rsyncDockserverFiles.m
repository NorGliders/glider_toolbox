function [xbds, logs, xbds_unprocessed, logs_unprocessed] = rsyncDockserverFiles(dockserver, xbd_dir, log_dir, varargin)
% rsyncDockserverFiles  Sync entire glider directory using rsync
% Based on GETDOCKSERVERFILES
%
%  Syntax:
%    [XBDS, LOGS, xbds_unprocessed, logs_unprocessed]  = GETDOCKSERVERFILES(DOCKSERVER, GLIDER, XBD_DIR, LOG_DIR)
%    [XBDS, LOGS] = GETDOCKSERVERFILES(DOCKSERVER, GLIDER, XBD_DIR, LOG_DIR, OPTIONS)
%    [XBDS, LOGS] = GETDOCKSERVERFILES(DOCKSERVER, GLIDER, XBD_DIR, LOG_DIR, OPT1, VAL1, ...)
%
%  [XBDS, LOGS] = GETDOCKSERVERFILES(DOCKSERVER, GLIDER, XBD_DIR, LOG_DIR) 
%  retrieves new binary files (.[smdtne]bd) and surface dialog files from the
%  glider named GLIDER from the remote dockserver defined by struct DOCKSERVER
%  to local directories XBD_DIR and LOG_DIR respectively, and returns the list
%  of downloaded files in string cell arrays XBDS and LOGS. Existing files in 
%  the local directories are updated only if they are smaller than remote ones.
%
%  DOCKSERVER is a struct with the fields needed by functions FTP or SFTP:
%    HOST: url as either fully qualified name or IP with optional port (string).
%    USER: user to access the dockserver if needed (string).
%    PASS: password of the dockserver if needed (string).
%    CONN: name or handle of connection type function, @FTP (default) or @SFTP.
%
%  [XBDS, LOGS] = GETDOCKSERVERFILES(DOCKSERVER, GLIDER, XBD_DIR, LOG_DIR, OPTIONS) and
%  [XBDS, LOGS] = GETDOCKSERVERFILES(DOCKSERVER, GLIDER, XBD_DIR, LOG_DIR, OPT1, VAL1, ...)
%  accept the following options, given in key-value pairs OPT1, VAL1... or in a
%  struct OPTIONS with field names as option keys and field values as option 
%  values, allowing to restrict the set of files to download:
%    XBD: binary file name pattern.
%      Download binary files matching given pattern only.
%      Its value may be any valid regular expression string or empty.
%      If empty no binary files are downloaded.
%      Default value: '^.+\.[smdtne]bd$'
%    LOG: log file name pattern.
%      Download log files matching given pattern only.
%      Its value may be any valid regular expression string or empty.
%      If empty no log files are downloaded.
%      Default value: '^.+\.log$' 
%    START: initial date of the period of interest.
%      If given, do not download files before the given date.
%      It may be any valid input compatible with XBD2DATE and LOG2DATE
%      options below, usually a serial date number.
%      Default value: -Inf
%    FINAL: final date of the period of interest.
%      If given, do not download files after the the given date.
%      It may be any valid input compatible with XBD2DATE and LOG2DATE
%      options below, usually a serial date number.
%      Default value: +Inf
%    XBD2DATE: date of binary file.
%      If date filtering is enabled, use the given function
%      to extract the date of a binary file from its attributes.
%      The function receives a struct in the format returned by function DIR
%      and should return a date in a format comparable to START and FINAL.
%      Default value: date from file name (see note on date filtering)
%    LOG2DATE: date of log file.
%      If date filtering is enabled, use the given function
%      to extract the date of a log file from its attribtues.
%      The function receives a struct in the format returned by function DIR
%      and should return a date in a format comparable to START and FINAL.
%      Default value: date from file name (see note on date filtering)
%    REMOTE_BASE_DIR: Root directory where the data live in the dockserver.
%    REMOTE_XBD_DIR: Path relative to REMOTE_BASE_DIR to the xbd files.
%    REMOTE_LOG_DIR: Path relative to REMOTE_BASE_DIR to the log files.
%    GLIDER: Name of the glider. It is used to build the directory path in
%      the remote server relative to REMOTE_BASE_DIR. If Glider is defined,
%      data path will be REMOTE_BASE_DIR/GLIDER/REMOTE_XBD_DIR or
%      REMOTE_BASE_DIR/GLIDER/REMOTE_LOG_DIR. Otherwise, XBD and LOG paths
%      are directly under REMOTE_BASE_DIR.%
%
%  Notes:
%    By default, date filtering is done based on the mission date computed
%    from the file names, not on the modification time. It relies on remote
%    file names having the conventional Slocum file name format.
%    For binary files it is:
%      ru07-2011-347-4-0.sbd
%    where
%      ru07: glider name.
%      2011: year in which the mission was started.
%      347: zero-based day of the year on which the mission was started.
%      4: zero-based mission number for the day the mission was started.
%      0: zero-based segment number of the current mission number.
%    For log files it is:
%      icoast00_modem_20120510T091438.log
%    where
%      icoast00: glider name.
%      modem: transmission method ('modem' or 'network').
%      20120510T091438: ISO 8601 UTC timestamp.
%
%    This function is based on the previous work by Tomeu Garau. He is the true
%    glider man.
%
%  Examples:
%    dockserver.host = 'ftp.mydockserver.org'
%    dockserver.user = 'myself'
%    dockserver.pass = 'top_secret'   
%    glider = 'happyglider'
%    xbd_dir = 'funnymission/binary'
%    log_dir = 'funnymission/log'
%    % Get all binary and log files.
%    [xbds, logs] = getDockserverFiles(dockserver, glider, xbd_dir, log_dir)
%    % Get only small files and no logs from missions started last week:
%    [xbds, logs] = ...
%      getDockserverFiles(dockserver, glider, xbd_dir, log_dir, ...
%                         'xbd', '^*.[st]bd$', 'log', [], ...
%                         'start', now()-7, 'final', now())
%
%  See also:
%    FTP
%    SFTP
%    DIR
%    REGEX
%
%  Authors:
%    Joan Pau Beltran  <joanpau.beltran@socib.cat>

%  Copyright (C) 2013-2016
%  ICTS SOCIB - Servei d'observacio i prediccio costaner de les Illes Balears
%  <http://www.socib.es>
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program.  If not, see <http://www.gnu.org/licenses/>.

  narginchk(3, 25);
  
  %% Set options and default values.
  % Old dockservers used this other base path:
  options.remote_base_dir = '/var/opt/gmc/gliders';
  options.remote_xbd_dir  = 'from-glider';
  options.remote_log_dir  = 'logs';
  options.local_base_dir  = '';
  options.processed_xbds  = {};
  options.processed_logs  = {};
  options.glider          = '';
  options.start           = -Inf;
  options.final           = +Inf;
  options.xbd             = '^.+\.[smdtne]bd$';
  options.log             = '^.+\.log$';
  options.xbd2date        = @(f)(datenum(str2double(regexp(f.name,...
      '^.*-(\d{4})-(\d{3})-\d+-\d+\.[smdtne]bd$','tokens','once'))...
      * [1 0 0; 0 0 1] + [0 0 1]));
  options.log2date        = @(f)(datenum(str2double(regexp(f.name,...
      '^\w+_\d{8}T\d{6}_(modem|network|freewave)_(net|tty_dgrp_pt)_\d{1}\.log$', ...
                                   'tokens','once'))));  % '^.*_.*_(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})\.log$'
                        
  
  %% Parse optional arguments.
  % Get option key-value pairs in any accepted call signature.
  argopts = varargin;
  if isscalar(argopts) && isstruct(argopts{1})
    % Options passed as a single option struct argument:
    % field names are option keys and field values are option values.
    opt_key_list = fieldnames(argopts{1});
    opt_val_list = struct2cell(argopts{1});
  elseif mod(numel(argopts), 2) == 0
    % Options passed as key-value argument pairs.
    opt_key_list = argopts(1:2:end);
    opt_val_list = argopts(2:2:end);
  else
    error('glider_toolbox:getDockserverFiles:InvalidOptions', ...
          'Invalid optional arguments (neither key-value pairs nor struct).');
  end
  % Overwrite default options with values given in extra arguments.
  for opt_idx = 1:numel(opt_key_list)
    opt = lower(opt_key_list{opt_idx});
    val = opt_val_list{opt_idx};
    if isfield(options, opt)
      options.(opt) = val;
    else
      error('glider_toolbox:getDockserverFiles:InvalidOption', ...
            'Invalid option: %s.', opt);
    end
  end


  %% Dockserver (remote) directory definition.
  remote_glider_dir = fullfile(options.remote_base_dir,lower(options.glider));
  remote_xbd_dir = fullfile(options.remote_base_dir,lower(options.glider),options.remote_xbd_dir);
  remote_log_dir = fullfile(options.remote_base_dir,lower(options.glider),options.remote_log_dir);
  
  
  %% Local directory definition. - might not use this
  local_glider_dir = fullfile(options.local_base_dir);
  local_xbd_dir = fullfile(options.local_base_dir,'binary');
  local_log_dir = fullfile(options.local_base_dir,'logs');
  
  
  %% Rsync between dockserver and local
  % rsync -rav --include="*.*d" --exclude="*.*" felliott@sfmc.webbresearch.com://var/opt/sfmc-dockserver/stations/bergen/gliders/durin/ ~/glider/from-sfmc/odin
  % For testing use --dry-run
  % from-glider binary files to  local binary dir
  start_files = how_many_files([local_xbd_dir '/*.*d']);
  disp('Syncing binary files...');
  command = ['rsync -rav --include="*.*d" --exclude="*.*" ' dockserver.user '@' dockserver.host ':' remote_xbd_dir '/ ' local_xbd_dir];
  [status,result] = system(command);
  if ~status
      loc = strfind(result, 'sent');
      trim_result = strtrim(result(loc:end));
      disp(trim_result)
  else
      disp(result)
  end
  end_files = how_many_files([local_xbd_dir '/*.*d']);
  disp(['New files downloaded: ' num2str(end_files - start_files)])
  
  
  % sync all other files from from-glider
  start_files = how_many_files(local_glider_dir);
  disp('Syncing other files from glider...');
  command = ['rsync -rav --exclude="*.*d" ' dockserver.user '@' dockserver.host ':' remote_xbd_dir ' ' local_glider_dir];
  [status,result] = system(command);
  if ~status
      loc = strfind(result, 'sent');
      trim_result = strtrim(result(loc:end));
      disp(trim_result)
  else
      disp(result)
  end
  end_files = how_many_files(local_glider_dir);
  disp(['New files downloaded: ' num2str(end_files - start_files)])
  
  
  % Sync logs, archive, and gliderstate.xml
  start_files = how_many_files(local_log_dir);
  disp('Syncing logs files...');
  command = ['rsync -rav --exclude="to-*" --exclude="from-*" --exclude="configuration" --exclude=".archived-deployments" ' dockserver.user '@' dockserver.host ':' remote_glider_dir '/ ' local_glider_dir];
  [status,result] = system(command);
  if ~status
      loc = strfind(result, 'sent');
      trim_result = strtrim(result(loc:end));
      disp(trim_result)
  else
      disp(result)
  end
  end_files = how_many_files(local_log_dir);
  disp(['New files downloaded: ' num2str(end_files - start_files)])

  
  %% Collect some parameters given in options.
  xbd_name      = options.xbd;
  log_name      = options.log;
  xbd_newfunc   = [];
  log_newfunc   = [];
  updatefunc    = @(l,r)(l.bytes < r.bytes);
  if isfinite(options.start) || isfinite(options.final)
    xbd_newfunc = @(r)(options.start <= options.xbd2date(r) && ...
                       options.xbd2date(r) <= options.final);
    log_newfunc = @(r)(options.start <= log2date(r) && ...
                       log2date(r) <= options.final);
  end

  
  %% List of unprocessed xbd files
  xbd_dir_struct = dir(local_xbd_dir);
  xbd_dir_cell   = {xbd_dir_struct.name}';
  xbd_dir_cell   = regexp(xbd_dir_cell, xbd_name, 'match');
  is_xbd_file    = cellfun('isempty',xbd_dir_cell);
  xbd_dir_files  = xbd_dir_cell(~is_xbd_file); 
  xbds           = [xbd_dir_files{:}]';
  if isempty(options.processed_xbds)
      xbds_unprocessed = xbds;
  else
      existing_xbds = options.processed_xbds.Properties.RowNames;
      [loc] = ismember(xbds, existing_xbds);
      xbds_unprocessed = xbds(~loc);
  end
  xbds = strcat([local_xbd_dir '/'],xbds);
  xbds_unprocessed = strcat([local_xbd_dir '/'],xbds_unprocessed);
  
  %% List of unprocessed log files
  % log_name = '^\w+_(modem|network|freewave)_\d{8}T\d{6}\.log$'
  % network: durin_20210123T115727_network_net_0.log
  % modem:   durin_20210119T233024_modem_tty_dgrp_pt_0.log
  %log_name_new  = '^\w+_\d{8}T\d{6}_\w(modem|network|freewave)_\w(net|tty_dgrp_pt)_\d{1}\.log$'
  log_name = '^\w+_*\.log$';
  log_dir_struct = dir(local_log_dir);
  log_dir_cell   = {log_dir_struct.name}';
  log_dir_cell   = regexp(log_dir_cell, log_name, 'match');
  is_log_file    = cellfun('isempty',log_dir_cell);
  log_dir_files  = log_dir_cell(~is_log_file);
  logs           = [log_dir_files{:}]';
  
  % restrict to start stop times
  % Identify log files created after startTime
  n = numel(logs);
  log_files_time = zeros(n,1);
  for i = 1:n
      dName      = logs{i};
      loc        = strfind(dName,'_');
      loc        = loc(1);
      dateText   = dName(loc+1:loc+15);
      log_files_time(i) = datenum(dateText,'yyyymmddTHHMMSS');
  end
  ind = find(log_files_time>options.start & log_files_time<options.final);
  logs = logs(ind);
  
  if isempty(options.processed_logs)
      logs_unprocessed = logs;
  else
      existing_logs = options.processed_logs.Properties.RowNames;
      [loc] = ismember(logs, existing_logs);
      logs_unprocessed = logs(~loc);
  end
  logs = strcat([local_log_dir '/'],logs);
  logs_unprocessed = strcat([local_log_dir '/'],logs_unprocessed);
  
  

end

function nofiles = how_many_files(mydir)
    % How many files in directory 'mydir'
    nofiles = [];
    cmd = ['ls ' mydir ' | wc -l'];
    [stat,res] = system(cmd);
    if ~stat
        nofiles = str2num(strtrim(res));
    end
end

