function public_paths = configRTPathsPublic()
%CONFIGRTPATHSPUBLIC  Configure public product and figure paths for glider deployment real time data.
%
%  Syntax:
%    PUBLIC_PATHS = CONFIGRTPATHSPUBLIC()
%
%  Description:
%    PUBLIC_PATHS = CONFIGRTPATHSPUBLIC() should return a struct
%    with the path patterns for the public copies of the deployment product
%    files generated by the glider processing chain in real time mode.
%    It should have the following fields:
%      FIGURE_DIR: path pattern of public directory for deployment figures.
%      FIGURE_URL: URL pattern pointing to public directory defined above.
%      FIGURE_INCLUDE: optional string cell array with the keys of the figures 
%        to be copied to the public location. If this fiels is not set, all
%        generated figures are copied.
%      FIGURE_EXCLUDE: optional string cell array with the keys of the figures
%        to exclude from copying to the public location.
%      FIGURE_INFO: path pattern of the public JSON file providing the list of 
%        deployment figures with their description and their URL. 
%      NETCDF_L0: path pattern of the public NetCDF file for raw data
%        (data provided by the glider without any meaningful modification).
%      NETCDF_L1: path pattern of the publict NetCDF file for processed
%        trajectory data (well referenced data with conversions, corrections,
%        and derivations).
%      NETCDF_L2: path pattern of the public NetCDF file for gridded data
%        (processed data interpolated on vertical instantaneous profiles).
%    These path patterns are converted to true paths through the function
%    STRFSTRUCT.
%
%  Notes:
%    Edit this file filling in the paths to reflect your desired file layout.
%
%  Examples:
%    public_paths = configRTPathsPublic()
%
%  See also:
%    MAIN_GLIDER_DATA_PROCESSING_RT
%    CONFIGRTPATHSLOCAL
%    STRFSTRUCT
%
%  Authors:
%    Joan Pau Beltran  <joanpau.beltran@socib.cat>

%  Copyright (C) 2013-2017
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

  error(nargchk(0, 0, nargin, 'struct'));

  netcdf_basedir        = '/data/current/opendap/observational/auv/glider';
  netcdf_glider_dir     = '${GLIDER_NAME,l,s/-/_}-${GLIDER_INSTRUMENT_NAME,l,s/-/_}';
  netcdf_deployment_dir = '${DEPLOYMENT_START,Tyyyy}';
  netcdf_l0  = 'dep${GLIDER_DEPLOYMENT_CODE,l}_${GLIDER_NAME,l}_${GLIDER_INSTRUMENT_NAME,l}_L0_${DEPLOYMENT_START,Tyyyy-mm-dd}_data_rt.nc';
  netcdf_l1  = 'dep${GLIDER_DEPLOYMENT_CODE,l}_${GLIDER_NAME,l}_${GLIDER_INSTRUMENT_NAME,l}_L1_${DEPLOYMENT_START,Tyyyy-mm-dd}_data_rt.nc';
  netcdf_l2  = 'dep${GLIDER_DEPLOYMENT_CODE,l}_${GLIDER_NAME,l}_${GLIDER_INSTRUMENT_NAME,l}_L2_${DEPLOYMENT_START,Tyyyy-mm-dd}_data_rt.nc';

  figure_basedir = '/home/glider/public_html/rt';
  figure_glider_dir     = '${GLIDER_NAME}';
  figure_deployment_dir = '${DEPLOYMENT_START,Tyyyymmdd}';
  figure_baseurl = 'http://www.socib.es/users/glider/rt';
  figure_list = '${DEPLOYMENT_ID,%d}_figures.json';

  public_paths.netcdf_l0 = fullfile(netcdf_basedir, netcdf_glider_dir, 'L0', netcdf_deployment_dir, netcdf_l0);
  public_paths.netcdf_l1 = fullfile(netcdf_basedir, netcdf_glider_dir, 'L1', netcdf_deployment_dir, netcdf_l1);
  public_paths.netcdf_l2 = fullfile(netcdf_basedir, netcdf_glider_dir, 'L2', netcdf_deployment_dir, netcdf_l2);
  public_paths.figure_dir = fullfile(figure_basedir, figure_glider_dir, figure_deployment_dir, 'figures');
  public_paths.figure_url = fullfile(figure_baseurl, figure_glider_dir, figure_deployment_dir, 'figures');
  public_paths.figure_info = fullfile(figure_basedir, figure_list);

end
