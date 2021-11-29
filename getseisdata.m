function seisdata = getseisdata(infdir, fname, tstart, tend, channel, outfdir, outformat)
% seisdata = getseisdata(infdir, outfdir, fname, len, channel)
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
% outformat    1 for MATLAB structure array
%              2 for SAC files
%
% OUTPUT:
% seisdata     A structure array that contains tendtime-series data in addition
%              to station- & earthquake- related information (i.e., name,
%              location, channel, etc.). This structure will only be
%              returned if "outformat" is 2.
%
% The structure will also be saved to "outfdir". In the case of SAC files,
% it will be saved to "outfdir".
% 
%
% SEE ALSO:
% Requires irisFetch from https://ds.iris.edu/ds/nodes/dmc/manuals/irisfetchm/
%
% Written by Huda Al Alawi (halawi@princeton.edu) - October 24, 2021.
% Last modified by Huda Al Alawi - November 24 2021.
%

% Define default values
defval('tstart', 15)
defval('tend', 25)outfdir
defval('channel', 'BHZ')

% Before doing anything, check tstart and tend values
if tend<tstart
    disp('tend must be after tstart')
    return
end

% Open the file and read the data, skip the headerlines
% #Network, Station, sLatitude, sLongitude, EventID, tOrigin, eLatitude, eLongitude, Depth(km)
fid = fopen(strcat(infdir, fname), 'r');
data = textscan(fid, '%s%s%f%f%d%s%f%f%f', 'HeaderLine', 10);
fclose(fid);

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

% Depending on the chosen "outformat", start requesting the data
switch outformat
    case 1
        % Let the structure hold 20k everytime (will make it usder-defined
        % limit later)
        sizestruct = 20000;
        % See how many 20ks in the array we have, and decide the number of
        % loop iterations accordingly
        if mod(length(net), sizestruct) ~= 0
            num = round(length(net)/sizestruct) + 1;
        else
            num = length(net)/sizestruct;
        end
        % Initialize a structure
        seis(sizestruct) = struct();
        
        % Now need to loop to save the structure every 20k
        % Set a variable for counting 20ks
        count20k = 0;
        for jj = 1:num
            % Define the new arrays
            % The starting and ending index...
            ind1 = (count20k*20000)+1;
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
            save(sprintf('%sdata%d', outfdir, count20k), 'seis');
            % Clear the structure
            clear seis
            % Update the count
            count20k = count20k + 1;
        end
        
    case 2
        
end


end