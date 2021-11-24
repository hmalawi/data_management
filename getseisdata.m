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
% seisdata     A structure array that contains time-series data in addition
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
% Last modified by Huda Al Alawi - November 12, 2021.
%

% Define default values
defval('tstart', 15)
defval('tend', 25)
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
newtime = datenum(datetime(newtime, 'InputFormat', 'yyyy-MM-dd HH:mm:ss'));

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
        % Initialize a structure
        seis = struct;
        % For all event-station pairs in the file, call irisFetch to get 
        % the data and store them into a structure array
        for ii = 1:length(net)
            tr = irisFetch.Traces(net(ii), sta(ii), '00', channel, t1(ii), t2(ii));
            % Check if data exists
            if isfield(tr, 'data') &&  ~isempty(tr.data)
                
            end
        end
        
    case 2
        
end


end