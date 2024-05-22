function varargout = deg2nmea(varargin)
%DEG2NMEA  Convert NMEA latitude and/or longitude degrees to decimal degrees.
%
%  Syntax:
%    NMEA = DEG2NMEA(DEG)
%    [NMEALAT, NMEALON] = DEG2NMEA(DEGLAT, DEGLON)
%
%  Description:
%    DEG = DEG2NMEA(NMEA) converts the scalar or array NMEA from NMEA latitude
%    or longitude degrees to decimal degrees applying the transformation:
%      DEG = FIX(NMEA/100) + REM(NMEA,100)/60;
%
%    [DEGLAT, DEGLON] = DEG2NMEA(NMEALAT, NMEALON) performs the same conversion
%    to each of its input arguments separately.
%
%  Examples:
%    DEG2NMEA(3330.00)
%    nmea = [36015.00 -445.25]
%    deg = DEG2NMEA(nmea)
%    nmealat = 3900.61662
%    nmealon = 257.99996
%    [deglat, deglon] = DEG2NMEA(nmealat, nmealon)
%
%  Notes:
%    The input values are not checked to be valid NMEA coordinate values.
%    So no warning is produced if the degree digits are out of [0,180] or
%    the integral part of de minute digits are out of [00,59].
%  
%  See also:
%    FIX
%    REM
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

  narginchk(1, 2);
  
  for varargidx = 1:numel(varargin)
    deg = varargin{varargidx};
    %nmea = fix(deg/100) + rem(deg,100)/60;
    signs = (~sign(deg))*-1;
    degrees = fix(deg);
    decimal = (abs(deg) - abs(fix(deg)))*60;
    nmea = strcat(num2str(degrees), num2str(decimal));
    varargout{varargidx} = nmea;
  end

end
