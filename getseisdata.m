function seisdata = getseisdata(infdir, fname, tstart, tend, channel, outfdir, outformat)
% seisdata = getseisdata(infdir, outfdir, fname, len, channel)
%
% This function facilitates downloading multi-seismograms for known 
% station-event pairs
%
%
% INPUT:
%
% infdir       The directory at which the input file is located (this
%              should be in the same format of EQDATA output file)
% fname        The name of the input file
% tstart       The relative start time of the requested portion of the
%              seismogram (in minutes assuming the origin time represents 
%              0 min) [defaulted]
% tend         The relative end time of the requested portion ot the
%              seismogram (in minutes assuming the origin time represents 
%              0 min) [defaulted]
% channel      The channel of interest [defaulted]
% outfdir      The directory at which the output files will be saved
% outformat    1 for SAC files
%              2 for MATLAB structure array
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
defval('tstart', 25)
defval('channel', 'BH*')

% Open the file and read the data, skip the headerlines
% #Network, Station, sLatitude, sLongitude, EventID, tOrigin, eLatitude, eLongitude, Depth(km)
fid = fopen(strcat(infdir, fname), 'r');
data = textscan(fid, '%s%s%f%f%d%s%f%f%f', 'HeaderLine', 10);

% 



end