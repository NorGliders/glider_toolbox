function public_paths = configPathsPublic(glider_toolbox_dir, public_site)
%CONFIGDTPATHSPUBLIC  Configure public product and figure paths for glider deployment delayed time data.
%
%  Syntax:
%    PUBLIC_PATHS = CONFIGPATHSPUBLIC()
%
%  Description:
%    PUBLIC_PATHS = CONFIGPATHSPUBLIC() should return a struct
%    with the path patterns for the public copies of the deployment product
%    files generated by the glider processing chain.
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
%    public_paths = configPathsPublic()
%
%  See also:
%    MAIN_GLIDER_DATA_PROCESSING_DT
%    CONFIGDTPATHSLOCAL
%    STRFSTRUCT
%
%  Authors:
%    Joan Pau Beltran  <joanpau.beltran@socib.cat>
%
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

  narginchk(1, 2);
  
  public_paths.base_dir    = fullfile(glider_toolbox_dir, 'glider_data', 'public', '${GLIDER_NAME}', '${DEPLOYMENT_START,Tyyyymmdd}', 'netcdf');
  public_paths.netcdf_l0   = fullfile('dep${GLIDER_DEPLOYMENT_CODE,l}_${GLIDER_NAME,l}_${GLIDER_INSTRUMENT_NAME,l}_L0_${DEPLOYMENT_START,Tyyyy-mm-dd}_data_rt.nc');
  public_paths.netcdf_l1   = fullfile('dep${GLIDER_DEPLOYMENT_CODE,l}_${GLIDER_NAME,l}_${GLIDER_INSTRUMENT_NAME,l}_L1_${DEPLOYMENT_START,Tyyyy-mm-dd}_data_rt.nc');
  public_paths.netcdf_l2   = fullfile('dep${GLIDER_DEPLOYMENT_CODE,l}_${GLIDER_NAME,l}_${GLIDER_INSTRUMENT_NAME,l}_L2_${DEPLOYMENT_START,Tyyyy-mm-dd}_data_rt.nc');
  
  public_paths.figure_dir     = fullfile('${GLIDER_NAME}', '${DEPLOYMENT_START,Tyyyymmdd}', 'figures');
  public_paths.figure_info    = '${DEPLOYMENT_ID,%d}_figures.json';
      
  % Data is not published if base_url is not input
  if isstruct(public_site) && ~isempty(fieldnames(public_site))
      public_paths.base_url       = public_site.base_url;
      public_paths.base_html_dir  = public_site.base_html_dir;
  end
end