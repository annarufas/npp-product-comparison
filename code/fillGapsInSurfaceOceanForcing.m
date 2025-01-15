function qData = fillGapsInSurfaceOceanForcing(data,mask,...
    data_lat,data_lon,mask_lat,mask_lon,t,maskThreshold,choiceMethod)

% FILLGAPSINSURFACEOCEANFORCING Fills temporal gaps in surface ocean
% data (e.g., chla, PAR0, NPP, dust flux) choosing between a standard 
% interp1 interpolation method, or a custom, multi-step interpolation 
% process. After interpolation, it applies a mask, which will set to NaN 
% cells that either do not meet a threshold criteria or are under the mask.
%
% For the custom method, it performs gap-filling in three distinct stages:
% 1. Single gaps: interpolates individual missing values (zeros) that 
%    are surrounded by valid data on both sides.
% 2. Consecutive gaps: fills sequences of multiple consecutive missing 
%    values (zeros) that are bounded by valid data at both ends.
% 3. Edge gap: handles gaps at the beginning or end of the time series 
%    (where valid data exists only on one side) by extrapolating values 
%    from the opposite end using a flip-based interpolation approach.
%
%   INPUT: 
%       data          - data array containing gaps (NaN values)
%       mask          - mask array
%       data_lat      - latitude vector for data 
%       data_lon      - longitude vector for data
%       mask_lat      - latitude vector for the mask 
%       mask_lon      - longitude vector for the mask
%       t             - time vector indices corresponding to the data (e.g., 1:12 for monthly data)
%       maskThreshold - ice fraction threshold above which ocean colour products become NaN (optional)
%       choiceMethod  - choose between (0) interp1 and (1) custom (optional)
%
%   OUTPUT:
%       qData         - data array with gaps filled in
%
%   WRITTEN BY A. RUFAS, UNIVERISTY OF OXFORD
%   Anna.RufasBlanco@earth.ox.ac.uk
%
%   Version 1.0 - Completed 9 Dec 2024  
%   Version 2.0 - 13 Jan 2025
%                   - Added sea ice fraction for masking                  
%                   - Gap-filling methods are now one function (this one)   
%
% =========================================================================
%%
% -------------------------------------------------------------------------
% PROCESSING STEPS
% -------------------------------------------------------------------------

%% Input validation

if size(data) ~= size(mask)
    error('Input data array and mask must have the same dimensions.');
end
if ndims(data) == 3 % a lat x lon x time array
    if length(t) ~= size(data, 3)
        error('Time vector length must match the 3rd dimension of the data array.');
    end
elseif ndims(data) == 1 % a time vector
    if length(t) ~= size(data)
        error('Time vector length must match the length of the data array.');
    end
end

 % Handle optional arguments
if nargin < 9 || isempty(choiceMethod)
    choiceMethod = 1; % default: custom interpolation
end
if nargin < 8 || isempty(maskThreshold)
    maskThreshold = []; % default: use with no threshold
end

%%  Regrid the mask to same grid used by data

if ndims(data) == 3 && ~isequal(size(data), size(mask))
    mask = regridMask(data_lat,data_lon,mask,mask_lat,mask_lon,t);
end

%% Interpolation and masking

qData = data; % copy the dataset

if ndims(data) == 3
    
    for iRow = 1:size(data,1)
        for iCol = 1:size(data,2)
            localData = squeeze(data(iRow,iCol,:)); 
            localMask = squeeze(mask(iRow,iCol,:));
            if any(isnan(localData))
                qData(iRow,iCol,:) = manageInterpolationAndMasking(...
                    localData,localMask,t,maskThreshold,choiceMethod);
            end
        end
    end
    
elseif ndims(data) == 1
    
    if any(isnan(data))
        qData = manageInterpolationAndMasking(data,mask,t,maskThreshold,choiceMethod);
    end
    
end

end % fillGapsInSurfaceOceanForcing

% =========================================================================
%%
% -------------------------------------------------------------------------
% LOCAL FUNCTIONS USED IN THIS SCRIPT
% -------------------------------------------------------------------------

% *************************************************************************

function qMask = regridMask(data_lat,data_lon,mask,mask_lat,mask_lon,t)
    
    % Original grid
    [X, Y, T] = ndgrid(mask_lat, mask_lon, t');

    % Query grid
    [qX, qY, qT] = ndgrid(data_lat, data_lon, t');

    % Interpolant -use first-order (linear) interpolation and extrapolation
    Fmask = griddedInterpolant(X, Y, T, mask, 'linear');

    % Regrid the mask from the original grid to the grid defined by data_lat and data_lon
    qMask = Fmask(qX, qY, qT);

end % regridMask

% *************************************************************************

function data = manageInterpolationAndMasking(dataOriginal,mask,t,maskThreshold,choiceMethod)

    % Make a copy
    data = dataOriginal; 
    
    % Perform interpolation only if at least two non-NaN values exist
    % (interpolation methods require at least 2 values)
    if sum(~isnan(data)) >= 2
        nanGaps = isnan(data);

        if choiceMethod == 0  
            data(nanGaps) = interp1(t(~nanGaps),data(~nanGaps),t(nanGaps),'linear','extrap')';
            
        elseif choiceMethod == 1

            while any(nanGaps) 
                
                % Check for NaNs at the beginning or end
                hasEdgeNaNs = isnan(data(1)) || isnan(data(end));
                
                if hasEdgeNaNs
                    % Handle gaps at the edges using flip-based ("capicúa") interpolation
                    data = interpolateEdgeGaps(data,t);
                else
                    % Handles the rest
                    data(nanGaps) = interp1(t(~nanGaps),data(~nanGaps),t(nanGaps),'linear','extrap')';
                end
                
                % Update
                nanGaps = isnan(data);
            end

        end
        
        % Set to NaN where mask is above a threshold and there were no data
        % to begin with originally
        data = applyMask(data,dataOriginal,mask,maskThreshold);
        
    else

        % Retain original values and set to NaN where mask is above a
        % threshold
        data = applyMask(data,dataOriginal,mask,maskThreshold);
        
    end
 
end % manageInterpolationAndMasking

% *************************************************************************

function dataFilled = interpolateEdgeGaps(dataOriginal,t)
% Handles gaps at the edges of the time series using flip-based extrapolation.
 
    % Make a copy
    dataFilled = dataOriginal;

    % Count NaNs from the beginning and the end
    nStartNans = find(~isnan(dataOriginal), 1) - 1; 
    nEndNans = length(dataOriginal) - find(~isnan(dataOriginal), 1, 'last'); 
    
    % Determine the number of edges that need to be filled in (either "1"
    % or "2")
    nNanEdges = (nStartNans > 0) + (nEndNans > 0);
    
    % Identify the first and last valid values
    idxFirstValid = find(dataOriginal >= 0,1,'first'); 
    idxLastValid = find(dataOriginal >= 0,1,'last'); 
    
    % Prepare interpolation vector
    lengthGap = nStartNans + nEndNans;
    wrapGapData = NaN(lengthGap+2, 1);
    wrapGapData(1) = dataOriginal(idxFirstValid);
    wrapGapData(end) = dataOriginal(idxLastValid);
    matchValidIdxs = find(~isnan(wrapGapData));
    matchNanIdxs = find(isnan(wrapGapData));
    
    % Vector filled in
    gapFilled = interp1(matchValidIdxs,wrapGapData(matchValidIdxs),...
        matchNanIdxs,'linear','extrap');
    
    % Handle the filling based on the number of edges
    if nNanEdges == 1 % either at the beginning or end, i.e., #######-------- (or) -------#######
     
        if idxFirstValid > t(1) % fill the start of the time series 
            dataFilled(1:idxFirstValid-1) = flip(gapFilled); 
        elseif idxFirstValid == t(1) % fill the end of the time series 
            dataFilled(idxLastValid+1:end) = flip(gapFilled); 
        end   
   
    elseif nNanEdges == 2 % both at the beginning and end, i.e.,  ------#####----- 
        
        % Fill both ends of the time series 
        nValsFirstSection = idxFirstValid-1;
        dataFilled(1:nValsFirstSection) = flip(gapFilled(1:nValsFirstSection));
        dataFilled(idxLastValid+1:end) = flip(gapFilled(nValsFirstSection+1:end));

    end
             
end % interpolateEdgeGaps

% *************************************************************************

function dataFilled = applyMask(dataFilled,dataOriginal,mask,maskThreshold)
    
    % Check if maskThreshold is provided, otherwise use default value of 0
    if nargin < 4 || isempty(maskThreshold)
        
        % Set to NaN cells where mask = 0
        maskInvalidPoints = (mask == 0);
        dataFilled(maskInvalidPoints) = NaN;

    elseif nargin == 4
        
        % Set to NaN cells where mask > threshold and there was no data to begin 
        % with originally
        maskInvalidPoints = (mask > maskThreshold) & isnan(dataOriginal);
        dataFilled(maskInvalidPoints) = NaN;
        
    % Handle the case when invalid number of arguments is provided
    else
        error('applyMask requires 3 or 4 input arguments.');
    end
    
end % applyMask

% *************************************************************************
