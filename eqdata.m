function eqdata(fdir, fname, minradius, maxradius, minmag, magtype, maxlim)
% eqdata(fdir, fname, minradius, maxradius, minmag, magtype, maxlim)
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
% minradius     Specify minimum distance from the geographic point defined by latitude and longitude [defaulted]
% maxradius     Specify maximum distance from the geographic point defined by latitude and longitude [defaulted]
% minmag        Limit to events with a magnitude larger than or equal to the specified minimum [defaulted]
% magtype       Type of Magnitude used to test minimum and maximum limits. Case insensitive. ex. ML Ms mb Mw all preferred [defaulted]
% maxlim        If the number of the founded earthquakes was larger that "maxlim", take only "maxlim" of them [defaulted]
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
% Last modified by Huda Al Alawi - Novermber 18, 2021.
%

% Define default values
datetime.setDefaultFormats('defaultdate', 'yyyy-MM-dd')
defval('minradius', 0)
defval('maxradius', 180)
defval('minmag', 5.5)
defval('magtype', 'mb')
defval('maxlim', 50)

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

% Convert the start and end time to proper format for irisFetch call
tstart = string(data{6});
tend = string(data{7});
% Remove the "T"
tstart = strcat(extractBefore(tstart,'T'), " ", extractAfter(tstart,'T'));
tend = strcat(extractBefore(tend,'T'), " ", extractAfter(tend,'T'));

% Open a file to print the final data
outfile = 'staevt.txt';
fid = fopen(strcat(fdir, outfile), 'w');
% Print some header lines
fprintf(fid, 'Stations were collected for\n %s %s %s %s', hlines{1}, ...
    hlines{2}, hlines{3}, hlines{4});
fprintf(fid, 'Earthquakes were specified to have\n A distance of [%.2f, %.2f] from the station\n A minimum magnitude of %.2f %s', ...
    minradius, maxradius, minmag, magtype);
fprintf(fid, '. The maximum number of earthquakes per station was chosen to be %d earthquakes\n\n',...
    maxlim);
% Data header
fprintf(fid, '#Network \t Station \t sLatitude \t sLongitude \t EventID \t tOrigin \t eLatitude \t eLongitude \t Depth(km) \n');

% For each station, we should find earthquakes within a distance
% between "minradius" and "maxradius"
for ii = 1:length(data{1})
    % Should use try/catch?
    try
    % Find the events here
    ev = irisFetch.Events('startTime', tstart(ii), ...
        'endTime', tend(ii),'radialcoordinates', [data{3}(ii), ...
        data{4}(ii), maxradius, minradius], 'MinimumMagnitude', minmag,...
        'magnitudeType', magtype);
    catch
        continue
    end
    
    % If no events where found, skip the station
    if isempty(ev)
        continue
    end
    
    % Sort the results by magnitude (descending)
    % Should take into account finding only one event (struct2table will
    % give an error in that case)
    if length(ev) == 1
        % #Network  Station  sLatitude  sLongitude  EventID  tOrigin  
        % eLatitude  eLongitude  Depth(km)
          fprintf(fid, '%-s %19s %19.3f %16.3f %17s %27s %21.3f %19.3f %20.2f', ...
              string(data{1}(ii)), string(data{2}(ii)), data{3}(ii), ...
              data{4}(ii), extractAfter(ev(1).PublicId, '='), ...
              ev(1).PreferredTime, ev(1).PreferredLatitude, ...
              ev(1).PreferredLongitude, ev(1).PreferredDepth);
          
    else 
        % First sort the data based on magnitude
        evtable = struct2table(ev);
        sortev = sortrows(evtable, 'PreferredMagnitudeValue', 'descend');
        evstruct = table2struct(sortev);
        
        
        % If the number of events was larger than "maxlim", only take "maxlim" of them
        if length(ev) > maxlim
            for jj = 1:maxlim
            % #Network  Station  sLatitude  sLongitude  EventID  tOrigin  
            % eLatitude  eLongitude  Depth(km)
            fprintf(fid, '%-s %19s %19.3f %16.3f %17s %27s %21.3f %19.3f %20.2f', ...
                string(data{1}(ii)), string(data{2}(ii)), data{3}(ii), ...
                data{4}(ii), extractAfter(evstruct(jj).PublicId, '='), ...
                evstruct(jj).PreferredTime, evstruct(jj).PreferredLatitude, ...
                evstruct(jj).PreferredLongitude, evstruct(jj).PreferredDepth);
            end
    % Else, just take them all
        else
            for jj = 1:length(evstruct)
            % #Network  Station  sLatitude  sLongitude  EventID  tOrigin  
            % eLatitude  eLongitude  Depth(km)
            fprintf(fid, '%-s %19s %19.3f %16.3f %17s %27s %21.3f %19.3f %20.2f', ...
                string(data{1}(ii)), string(data{2}(ii)), data{3}(ii), ...
                data{4}(ii), extractAfter(evstruct(jj).PublicId, '='), ...
                evstruct(jj).PreferredTime, evstruct(jj).PreferredLatitude, ...
                evstruct(jj).PreferredLongitude, evstruct(jj).PreferredDepth);
            end
        end
        
    end
    
end

fclose(fid);

end