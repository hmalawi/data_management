function getseisdata(infdir, outfdir, fname, len, channel)
% getseisdata(infdir, outfdir, fname, len, channel)
%
% This function facilitates downloading multi-seismograms for known 
% station-event pairs
%
%
% INPUT:
%
% infdir     The directory at which the input file is located
% fname      The name of the input file
% outfdir    The directory at which the output files will be saved
% len        The length of the desired seismograms in seconds [defaulted]
% channel    The channel of interest [defaulted]
%
% OUTPUT:
% No arguments will be returned. The seismograms will be saved in (outdir)
% as SAC files
%
% SEE ALSO:
% Requires irisFetch from https://ds.iris.edu/ds/nodes/dmc/manuals/irisfetchm/
%
% Written by Huda Al Alawi (halawi@princeton.edu) - October 24, 2021.
% Last modified by Huda Al Alawi - October 29, 2021.
%

% Define default values
defval('channel', 'BH*')
defval('len', 90)

% Open the file and read the data, skip the headerlines
% #Network, Station, sLatitude, sLongitude, EventID, tOrigin, eLatitude, eLongitude, Depth(km)
fid = fopen(strcat(infdir, fname), 'r');
data = textscan(fid, '%s%s%f%f%d%s%f%f%f', 'HeaderLine', 10);





end