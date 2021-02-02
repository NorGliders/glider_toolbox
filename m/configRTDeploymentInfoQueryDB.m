function [sql_query, deployment_fields] = configRTDeploymentInfoQueryDB()
%CONFIGRTDEPLOYMENTINFOQUERYDB  Configure the query to retrieve real time glider deployment information.
%
%  Syntax:
%    [SQL_QUERY, DEPLOYMENT_FIELDS] = CONFIGRTDEPLOYMENTINFOQUERYDB()
%
%  Description:
%    [SQL_QUERY, DEPLOYMENT_FIELDS] = CONFIGRTDEPLOYMENTINFOQUERYDB() should 
%    return the SQL query to retrieve the information about glider deployments
%    to be processed in real time. String SQL_QUERY is the query to execute. 
%    The mapping between deployment fields and data base table columns is given 
%    by the string cell array DEPLOYMENT_FIELDS. Deployment fields are described 
%    in GETDEPLOYMENTINFODB.
%
%  Notes:
%    Edit this file filling in the field mapping of your data base and the
%    query that returns that fields for each deployment.
%
%  Examples:
%    [sql_query, deployment_fields] = configRTDeploymentInfoQueryDB()
%
%  See also:
%    GETDEPLOYMENTINFODB
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

  narginchk(0, 0);

  % Select the deployment fields.
  % First column is deployment field
  % Second column is column in data base table.
  % Edit for UIB OGDB - FE 18.01.2021
  fields_map = {
    'deployment_id'          'deployment_id'
    'deployment_name'        'deployment_name'
    'deployment_start'       'deployment_start'
    'deployment_end'         'deployment_end'
    'glider_name'            'glider_name'
    'glider_serial'          'glider_serial'
    'glider_model'           'glider_model'
    'glider_instrument_name' 'glider_instrument_name'
    'glider_deployment_code' 'deployment_name'
    % Optional fields for global attributes.
    'abstract'                     'abstract'
    'acknowledgement'              'acknowledgement'
    'author'                       'author'
    'author_email'                 'author_email'
    'creator'                      'creator'
    'creator_email'                'creator_email'
    'creator_url'                  'creator_url'
    'data_center'                  'data_center'
    'data_center_email'            'data_center_email'
    'institution'                  'institution'
    'institution_references'       'institution_references'
    'instrument'                   'instrument'
    'instrument_manufacturer'      'instrument_manufacturer'
    'instrument_model'             'instrument_model'
    'license'                      'license'
    'principal_investigator'       'principal_investigator'
    'principal_investigator_email' 'principal_investigator_email'
    'project'                      'project'
    'publisher'                    'publisher'
    'publisher_email'              'publisher_email'
    'publisher_url'                'publisher_url'
    'summary'                      'summary'
    % fields added for the EGO format
    'citation'                     'citation'
    'wmo_platform_code'            'wmo_platform_code'
    'platform_code'                'platform_code'
    'deployment_label'             'deployment_label'
    'id'                           'deployment_name'
    'deployment_cruise_id'         'deployment_cruise_id'
    'glider_owner'                 'glider_owner'
    'operating_institution'        'operating_institution'
    'platform_type'                'platform_type'
    'platform_maker'               'platform_maker'
  };

  deployment_fields = fields_map(:,1)';
  database_fields = fields_map(:,2)';

  % Build the query.
  database_fields_str = ...
    [sprintf('%s, ', database_fields{1:end-1}) database_fields{end}];
  % UIB query
  sql_query = ['SELECT ' database_fields_str ' FROM public.main WHERE (status=''active'');'];
  %test = fetch(conn, sql);

%   sql_query = ['select ' database_fields_str ...
%                '  from instrumentation.deployment' ...
%                '  inner join instrumentation.instrument' ...
%                '    on (deployment_instrument_id=instrument_id)' ...
%                '  inner join instrumentation.instrument_type' ...close(conn);
%                '    on (instrument_instrument_type_id=instrument_type_id)' ...
%                '  inner join instrumentation.instrument_platform' ...
%                '    on (instrument_platform_instrument_id=instrument_id and instrument_platform_installation_date < now() and (instrument_platform_uninstallation_date is null or instrument_platform_uninstallation_date > now()))' ...
%                '  inner join instrumentation.platform' ...
%                '    on (instrument_platform_platform_id = platform_id)' ...
%                '  inner join instrumentation.institution' ...
%                '    on (deployment_institution_id=institution_id)' ...
%                '  where (instrument_type_name~*''glider'' and deployment_initial_date < now() and deployment_finished=false);'];


end
