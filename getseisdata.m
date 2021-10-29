function getseisdata(infdir, outfdir, fname, tstart, tend, channel)
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
% tstart     The relative start time of the requested portion of the
%            seismogram (in minutes assuming the origin time represents 0
%            min) [defaulted]
% tend       The relative end time of the requested portion ot the
%            seismogram (in minutes assuming the origin time represents 0
%            min) [defaulted]
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
defval('tstart', 15)
defval('tstart', 25)
defval('channel', 'BH*')

% Open the file and read the data, skip the headerlines
% #Network, Station, sLatitude, sLongitude, EventID, tOrigin, eLatitude, eLongitude, Depth(km)
fid = fopen(strcat(infdir, fname), 'r');
data = textscan(fid, '%s%s%f%f%d%s%f%f%f', 'HeaderLine', 10);

% 



end