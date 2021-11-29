function seis = getseisdata(infdir, fname, tstart, tend, channel,...
    outfdir, sizestruct)
% seis = getseisdata(infdir, fname, tstart, tend, channel,...
%    outfdir, sizestruct, outformat)
%
% This function facilitates downloading multi-seismograms for known 
% station-event pairs
%
%
% INPUT:
%
% infdir       The directory at which the input file is located
% fname        The name of the input file (this should be in the same 
%              format of EQDATA output file)
% tstart       The relative start time of the requested portion of the
%              seismogram (in minutes assuming the origin time represents 
%              0 min): positive after the origin, negetive before the origin [defaulted]
% tend         The relative end time of the requested portion ot the
%              seismogram (in minutes assuming the origin time represents 
%              0 min): positive after the origin, negetive before the origin [defaulted]
% channel      The channel of interest [defaulted]
% outfdir      The directory at which the output files will be saved
% sizestruct   MATLAB arrays have a size limit. If the data is too large,
%              consider writing the data into multiple structures each of
%              size "sizestruct" [defaulted: alldata]
%
% OUTPUT:
%
% seis         A nested structure array that contains structures holding
%              time-series data for each event-station pair in addition to 
%              station- & earthquake- related information (i.e., name, 
%              location, channel, etc.). It will also be saved to outfdir. 
%              There might be empty structures (correspondnig to
%              no-data-found requests). To obtain SAC files from these 
%              structures, see irisFetch.Trace2SAC
%
%
% SEE ALSO:
% Requires irisFetch from https://ds.iris.edu/ds/nodes/dmc/manuals/irisfetchm/
%
% Written by Huda Al Alawi (halawi@princeton.edu) - October 24, 2021.
% Last modified by Huda Al Alawi - November 29 2021.
%

% Define default values
defval('tstart', 15)
defval('tend', 25)
defval('channel', 'BHZ')

% Before doing anything, check tstart and tend values
if tend<tstart
    disp('end_time must be after start_time')
    return
end

% Open the file and read the data, skip the headerlines
% #Network, Station, sLatitude, sLongitude, EventID, tOrigin, eLatitude, eLongitude, Depth(km)
fid = fopen(strcat(infdir, fname), 'r');
data = textscan(fid, '%s%s%f%f%d%s%f%f%f', 'HeaderLine', 10);
fclose(fid);

% One last default value
defval('sizestruct', length(data{1}))

% Assign the data that we need to meaningful variables for easy access when
% call irisFetch
net = string(data{1,1});
sta = string(data{1,2});
eqtime = string(data{1,6});
% Remove T from eqtime to make it agree with one of datetime format
newtime = strcat(extractBefore(eqtime,'T'), " ", extractAfter(eqtime,'T'));
% Convert newtime from string to serial date number
% BE CAREFUL, the format is case sensitive (check datetime documentation)
newtime = datenum(datetime(newtime, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.S'));

% Now need to define t1 & t2 to use irisFetch
% addtodate only works for scalar! Cannot add to the whole array at once
% Initialize vectors to make it faster
t1 = zeros(length(newtime), 1);
t2 = zeros(length(newtime), 1);
% Loop through
for ii = 1:length(t1)
    t1(ii) = addtodate(newtime(ii), tstart, 'minute');
    t2(ii) = addtodate(newtime(ii), tend, 'minute');
end

% Now convert to string with the format accepted by irisFetch
% BE CAREFUL, it's case sensitive & different from the one used before.
% Check datestr documentation
t1 = string(datestr(t1, 'yyyy-mm-dd HH:MM:SS'));
t2 = string(datestr(t2, 'yyyy-mm-dd HH:MM:SS'));


% See how many "sizestruct" in the array we have, and decide the number of
% loop iterations accordingly
if mod(length(net), sizestruct) ~= 0
    num = round(length(net)/sizestruct) + 1;
else
    num = length(net)/sizestruct;
end
% Initialize a structure, maybe need to move this later
seis(sizestruct) = struct();

% Now need to loop to save the structure every "sizestruct"
% Set a variable for counting
countnum = 0;
for jj = 1:num
    % Define the new arrays
    % The starting and ending index...
    ind1 = (countnum*sizestruct)+1;
    ind2 = ind1+sizestruct-1;
    % Check if the ending index exceeded the length of the original
    % data. Define the new arrays accordingly
    if ind2 <= length(net)
        newnet = net(ind1:ind2);
        newsta = sta(ind1:ind2);
        newt1 = t1(ind1:ind2);
        newt2 = t2(ind1:ind2);
    else
        newnet = net(ind1:end);
        newsta = sta(ind1:end);
        newt1 = t1(ind1:end);
        newt2 = t2(ind1:end);
    end 

    % For all event-station pairs in the file, call irisFetch to get 
    % the data and store them into a structure array
    for ii = 1:sizestruct
        ii
        try
            tr = irisFetch.Traces(newnet(ii), newsta(ii), '*', channel, newt1(ii), newt2(ii));
        catch
            % If couldn't find the data, assign the index to 1 and skip
            continue
        end
        % If data was found, store it into a structure
        seis(ii).evesta = tr;
    end
    % Save the structure
    save(sprintf('%sdata%d', outfdir, countnum), 'seis');
    % Clear the structure
    clear seis
    % Update the count
    countnum = countnum + 1;
end


end