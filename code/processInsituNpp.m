function insituNppMonthlyAvg = processInsituNpp(filenameInputInsituNpp,labelLocations)

% PROCESSINSITUNPPDATA Processes NPP observation data and computes 
% monthly averages for each of our study locations in filenameInputInsituNpp.

    % Load and preprocess data
    data = loadAndPreprocessData(filenameInputInsituNpp);

    % Filter and integrate depth-specific data for BATS/OFP
    columnNamesToExtractFromDataTable = {'tag', 'NPP_mg_C_m2_d', 'month', 'year'};
    dataBatsDepthIntegrated = integrateBatsData(data,columnNamesToExtractFromDataTable);

    % Combine station data and compute monthly averages
    insituNppMonthlyAvg = computeMonthlyAverages(data,dataBatsDepthIntegrated,...
        columnNamesToExtractFromDataTable,labelLocations);

end % processInsituNpp

% =========================================================================
%%
% -------------------------------------------------------------------------
% LOCAL FUNCTIONS USED IN THIS SCRIPT
% -------------------------------------------------------------------------

function data = loadAndPreprocessData(filename)
    
    % Load data with specified import options
    opts = detectImportOptions(fullfile('.','data','raw',filename));
    opts = setvartype(opts, {'NPP_mg_C_m2_d', 'NPP_mg_C_m3_d'}, 'double');
    data = readtable(fullfile('.','data','raw',filename), opts);

    % Add month, year columns, and convert tag to categorical
    data.month = categorical(month(data.date));
    data.year = year(data.date);
    data.tag = categorical(data.tag);
    
end % loadAndPreprocessData

% *************************************************************************

function batsDataDepthIntegrated = integrateBatsData(data,columnNamesToExtract)
    
    % Filter for BATS data
    dataBats = data(data.tag == 'BATS',:);

    % Sort rows by tag, depth, and date
    dataBats = sortrows(dataBats, {'tag', 'depth', 'date'});

    % Find unique dates 
    uniqueDates = unique(dataBats.date, 'rows');
    nSamples = numel(uniqueDates);
    
    % Preallocate output table
    batsDataDepthIntegrated = table('Size', [nSamples, numel(columnNamesToExtract)], ...
        'VariableTypes', {'categorical', 'double', 'double', 'double'}, ...
        'VariableNames', columnNamesToExtract);
    batsDataDepthIntegrated.tag = categorical(repmat({'BATS'}, nSamples, 1));

    % Perform depth integration for each unique date and save into output
    % table
    for iSample = 1:nSamples
        % Select data for the current date
        profileDepths = dataBats.depth(dataBats.date == uniqueDates(iSample));
        profileNpp = dataBats.NPP_mg_C_m3_d(dataBats.date == uniqueDates(iSample));

        % Integrate NPP over depth using the trapezoidal rule
        batsDataDepthIntegrated.NPP_mg_C_m2_d(iSample) = trapz(profileDepths, profileNpp);

        % Assign month and year
        batsDataDepthIntegrated.month(iSample) = month(uniqueDates(iSample));
        batsDataDepthIntegrated.year(iSample) = year(uniqueDates(iSample));
    end

    % Convert month to categorical
    batsDataDepthIntegrated.month = categorical(batsDataDepthIntegrated.month);
    
end % integrateBatsData

% *************************************************************************

function nppMonthlyAvg = computeMonthlyAverages(data,batsDataDepthIntegrated,...
    columnNamesToExtract,locationNames)
    
    % Extract station-specific data (IN THIS ORDER, WHICH FOLLOWS
    % locationNames)
    nppDepthIntegrated = vertcat(...
        data(data.tag == 'ALOHA', columnNamesToExtract), ...
        batsDataDepthIntegrated, ...
        data(data.tag == 'EqPac', columnNamesToExtract), ...
        data(data.tag == 'OSP', columnNamesToExtract));

    % Replace NaN values with 0
    nppDepthIntegrated.NPP_mg_C_m2_d(isnan(nppDepthIntegrated.NPP_mg_C_m2_d)) = 0;

    % Compute monthly averages for each station
    nppMonthlyAvg = array2table(NaN(12, numel(locationNames)), ...
        'VariableNames', cellstr(locationNames),...
        'RowNames', arrayfun(@num2str, 1:12, 'UniformOutput', false));

    for iLoc = 1:numel(locationNames)
        % Filter data for the current station
        currStatData = nppDepthIntegrated(nppDepthIntegrated.tag == locationNames(iLoc), :);
        % Loop over each month
        for iMonth = 1:12
            currMonthData = currStatData(currStatData.month == num2str(iMonth),:);
            if ~isempty(currMonthData)
                nppMonthlyAvg{iMonth,locationNames{iLoc}} = mean(currMonthData.NPP_mg_C_m2_d);
            end
        end
    end
    
end % computeMonthlyAverages

% *************************************************************************