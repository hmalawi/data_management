function eqdata(fdir, fname, tstart, tend, minradius, maxradius, minmag, magtype)
% eqdata(fdir, fname, tstart, tend, minradius, maxradius, minmag, magtype)
%
% This function is to get information about events from IRIS services
% website based on specific start and end time, and within a certain
% epicentral distance from a station.
%
%
% INPUT:
%
% fdir          The directory at which the input file is located and output file will be saved
% fname         The name of file that contains stations info. (output of STAINFO)
% tstart        Limit to events occurring on or after the specified start time [defaulted]
% tend          Limit to events occurring on or before the specified end time [defaulted]	
% minradius     Specify minimum distance from the geographic point defined by latitude and longitude [defaulted]
% maxradius     Specify maximum distance from the geographic point defined by latitude and longitude [defaulted]
% minmag        Limit to events with a magnitude larger than or equal to the specified minimum [defaulted]
% magtype       Type of Magnitude used to test minimum and maximum limits. Case insensitive. ex. ML Ms mb Mw all preferred [defaulted]
%
% All time should be in this format: 1991-01-01T00:00:00
% minradius and maxradius have values from 0 to 180 degrees
% Longitude ranges from -180 to 180 degrees
% With no specified arguments, tend is set to be today's date & tstart yesterday's date (at T00:00:00), 
% minradius 0 and maxradius 180, and minmag 5.
% 
%
% OUTPUT:
% No arguments will be returned. There will be an output file saved in to the directory fdir. Will include:
% #Network  Station  sLatitude  sLongitude  EventID  tOrigin  eLatitude  eLongitude  Depth(km)
%
%
% SEE ALSO:
%
% STAINFO
%
%
% Written by Huda Al Alawi (halawi@princeton.edu) - November 11, 2020.
% Last modified by Huda Al Alawi - Novermber 17, 2021.
%

% To get data from IRIS Web Services
evturl = 'http://service.iris.edu/fdsnws/event/1/';
outformat = 'text';

datetime.setDefaultFormats('defaultdate', 'yyyy-MM-dd')
% Define default values
defval('tstart', strcat(string(datetime('yesterday')),'T00:00:00'))
defval('tend', strcat(string(datetime('today')), 'T00:00:00'))
defval('minradius', 0)
defval('maxradius', 180)
defval('minmag', 5)
defval('magtype', 'mb')

% Prepare the general form of the request
evturl = strcat(evturl, 'query?starttime=%s&endtime=%s&latitude=%f&longitude=%f&minradius=%f&maxradius=%f&minmagnitude=%f&includeallmagnitudes=true&magtype=%s&orderby=magnitude&format=%s');
% Open the file that contains stations information
fid = fopen(strcat(fdir, fname), 'r');
% Read the data, will need the the header lines (2-5) for later
fgets(fid);
for ii=1:4
hlines{ii}=fgets(fid);
end
% Those will be 1.Networks, 2.Stations, 3.Lat, 4.Lon, 5.Elevation,
% 6.tStart, 7.tEnd
data = textscan(fid, '%s%s%f%f%f%s%s', 'HeaderLine', 2);
fclose(fid);

% Convert start and end time to the proper format rather than string. Will
% need it later!
stastart = datetime(str2double(string(extractBetween(data{1,6}(:), 1, 4)))...
    , str2double(string(extractBetween(data{1,6}(:), 6, 7))), ...
    str2double(string(extractBetween(data{1,6}(:), 9, 10))));
staend = datetime(str2double(string(extractBetween(data{1,7}(:), 1, 4)))...
    , str2double(string(extractBetween(data{1,7}(:), 6, 7))), ...
    str2double(string(extractBetween(data{1,7}(:), 9, 10))));

% Open a file to print the final data
outfile = 'staevt.txt';
fid = fopen(strcat(fdir, outfile), 'w');
% Print some header lines
fprintf(fid, 'Stations were collected for\n %s %s %s %s', hlines{1}, ...
    hlines{2}, hlines{3}, hlines{4});
fprintf(fid, 'Earthquakes were specified to have\n A distance of [%.2f, %.2f] from the station\n A minimum magnitude of %.2f %s', ...
    minradius, maxradius, minmag, magtype);
fprintf(fid, 'The maximum number of earthquakes per station was chosen to be %d earthquakes\n\n',...
    num);
% Data header
fprintf(fid, '#Network \t Station \t sLatitude \t sLongitude \t EventID \t tOrigin \t eLatitude \t eLongitude \t Depth(km) \n');

% For each station, we should find earthquakes within a distance
% between "minradius" and "maxradius"
for ii = 1:length(data{1})
    someevt = sprintf(evturl, tstart, tend, data{1,3}(ii), data{1,4}(ii), ...
        minradius, maxradius, minmag, magtype, outformat);
    % Read the data from the URL
    options = weboptions('Timeout', 120);
    evt = webread(someevt, options);
    % If no events were found for the given specifications, skip this
    % station
    if isempty(evt) == 1
        continue
    end
    
    % Trying to extract the information here...
    pos = strfind(evt, '|');
    % Find the number of readings and remove the ones of the header
    n = (length(pos) - 12) / 12;
    evtstruct = textscan(evt', '%d%s%f%f%f%s%s%s%s%s%s%s%s', n, 'HeaderLines', 1, 'Delimiter', '|');
    origin = datetime(str2double(string(extractBetween(evtstruct{1,2}(:), 1, 4))),...
        str2double(string(extractBetween(evtstruct{1,2}(:), 6, 7))), ...
        str2double(string(extractBetween(evtstruct{1,2}(:) , 9 , 10))));
    
    for jj = 1:length(evtstruct{1})
        % We need to check if the origin time of the earthquake is within the
        % recording time of the station. Keep it if true
        if isbetween(origin(jj) , stastart(ii) , staend(ii)) == 1
            % #Network  Station  sLatitude  sLongitude  EventID  tOrigin  
            % eLatitude  eLongitude  Depth(km)
            % Have to work on the format a little bit, later...
            fprintf(fid, '%-s %19s %19.3f %16.3f %17d %27s %21.3f %19.3f %20.2f', ...
                string(data{1}(ii)), string(data{2}(ii)), data{3}(ii), ...
                data{4}(ii), evtstruct{1}(jj), string(evtstruct{2}(jj)),...
                evtstruct{3}(jj), evtstruct{4}(jj), evtstruct{5}(jj));
        end
    end
end

fclose(fid);

end