function stainfo(fdir, tstart, tend, minlat, maxlat, minlon, maxlon)
% stainfo(fdir, tstart, tend, minlat, maxlat, minlon, maxlon)
%
% This function is to get main details of stations from IRIS services
% website based on specific start and end time, and within a certain
% location defined by its longitude and latitude ranges.
%
%
% INPUT:
%
% fdir       The directory at which the output file will be saved
% tstart     Limit to metadata describing channels operating on or after the specified start time [defaulted]
% tend       Limit to metadata describing channels operating on or before the specified end time [defaulted]	
% minlat     Southern boundary [defaulted]
% maxlat     Northern boundary [defaulted]
% minlon     Western boundary [defaulted]
% maxlon     Eastern boundary [defaulted]
%
% All time should be in this format: 1991-01-01T00:00:00
% Latitude ranges from -90 to 90 degrees
% Longitude ranges from -180 to 180 degrees
% With no specified arguments, tend is set to be today's date & tstart yesterday's date (at T00:00:00), 
% latitude [-90:90] and longitude [-180:180]
% 
%
% OUTPUT:
% No arguments will be returned. There will be an output file 'stationinfo.txt' saved in to the directory fdir. Will include:
% #Network  Station  Latitude  Longitude  Elevation  StartTime  EndTime
% There are stations which do not have end time (still operating). Today's
% date will be assigned to those to avoid issues when using EQDATA.M
%
% Written by Huda Al Alawi (halawi@princeton.edu) - November 11th, 2020.
% Last modified by Huda Al Alawi - October 8th, 2021.
%

% To get data from IRIS Web Services
staurl = 'http://service.iris.edu/fdsnws/station/1/';
outformat = 'text';

% Define default values
defval('tstart', strcat(string(datetime('yesterday')),'T00:00:00'))
defval('tend', strcat(string(datetime('today')),'T00:00:00'))
defval('minlat', -90)
defval('maxlat', 90)
defval('minlon', -180)
defval('maxlon', 180)
datetime.setDefaultFormats('defaultdate', 'yyyy-MM-dd')

% Prepare the link
staurl = strcat(staurl, 'query?starttime=%s&endtime=%s&minlatitude=%f&maxlatitude=%f&minlongitude=%f&maxlongitude=%f&format=%s');
staurl = sprintf(staurl, tstart, tend, minlat, maxlat, minlon, maxlon, outformat);

% Read the data from the URL
% Try to request url
    try
        options = weboptions('Timeout', 90);
        sta = webread(staurl, options);
        if isempty(sta)
            error('No data found')
        end
    % If the link doesn't work, display a message
    catch
        error('The link cannot be accessed. Possible reasons: no data found, timeout error, invalid input')
    end

% Trying to extract the information here...
pos = strfind(sta, '|');
% Find the number of readings and remove the ones of the header
n = (length(pos) -7 ) / 7;
stastruct = textscan(sta', '%s%s%f%f%f%s%s%s', n, 'HeaderLines', 1, 'Delimiter', '|');
% Some stations have no end time (still operating). If that's the case,
% find the indices to replace it later with today's date
idx = cellfun(@isempty , stastruct{1,8}(:));

% Open file to print data
fname = 'stationinfo.txt';
fid = fopen(strcat(fdir, fname), 'a');
% Print some header lines
fprintf(fid, 'Stations collected for \n Latitude: [%.2f, %.2f] \n Longitude: [%.2f, %.2f] \n Start time: %s \n End time %s \n \n', ...
    minlat, maxlat, minlon, maxlon, tstart, tend);
fprintf(fid, '#Network \t Station \t Latitude \t Longitude \t Elevation \t StartTime \t \t EndTime \n');
% Print data to file, remember replacing empty (endt) with today's date
endt = string(stastruct{8});
endt(idx) = strcat(string(datetime('today')),'T00:00:00');
for ii = 1:length(endt)
    fprintf(fid, '%-s %20s %18.3f %16.3f %16.2f %28s %24s \n', string(stastruct{1}(ii)), ...
        string(stastruct{2}(ii)), stastruct{3}(ii), stastruct{4}(ii), ...
        stastruct{5}(ii), string(stastruct{7}(ii)), endt(ii));
end

fclose(fid);

end