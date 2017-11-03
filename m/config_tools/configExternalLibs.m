function wrc_progs = configExternalLibs(glider_toolbox_dir)
%CONFIGWRCPROGRAMS  Configure path of the Slocum glider programs provided by WRC.
%  TODO: update documentation
%
%  Syntax:
%    WRC_PROGS = CONFIGWRCPROGRAMS()
%
%  Description:
%    WRC_PROGS = CONFIGWRCPROGRAMS() should return a struct with the path to
%    the executables provided by the Webb Research Company to deal with Slocum
%    glider data files. It should have the following fields:
%      DBD2ASC: path to the program to convert Slocum binary data files
%        to ascii data ('dbd2asc').
%
%    The following fields are optional. The glider processing functions do not
%    use them in any way. They are here just for completeness and to allow
%    using these programs from the MATLAB/Octave environment in which the
%    glider processing toolbox is used.
%      DBA_MERGE: path to program to merge ascii versions of the navigation
%        and science files ('dba_merge').
%      DBA_SENSOR_FILTER: path to program to filter data in ascii versions of
%        the Slocum data files based on the source sensor ('dba_sensor_filter').
%      DBA_TIME_FILTER: path to program to filter data in ascii versions of
%        the Slocum data files based on the time stamp ('dba_time_filter').
%      DBA2_ORIG_MATLAB: path to program to convert ascii versions of the 
%        Slocum data files to MATLAB/Octave loadable files ('dba2_orig_matlab').
%      RENAME_DBD_FILES: path to program to perform 8x3 DOS name format 
%        renaming of the Slocum binary data files ('rename_dbd_files').
%
%  Notes:
%    The executables required are provided by the Webb Research Company and
%    should be available in your system binary path as required by the
%    XBD2DBA function.
%
%  Examples:
%    wrc_progs = configWRCPrograms()
%
%  See also:
%    XBD2DBA
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

  narginchk(1, 1);
  
  wrc_progs.base_dir          = fullfile(glider_toolbox_dir, 'ext_lib', 'bin');
  % This program is needed.
  wrc_progs.dbd2asc           = fullfile('dbd2asc');
  % These programs are optional.
  wrc_progs.dba_merge         = fullfile('dba_merge');
  wrc_progs.dba_sensor_filter = fullfile('dba_sensor_filter');
  wrc_progs.dba_time_filter   = fullfile('dba_time_filter');
  wrc_progs.dba2_orig_matlab  = fullfile('dba2_orig_matlab');
  wrc_progs.rename_dbd_files  = fullfile('rename_dbd_files');

end
