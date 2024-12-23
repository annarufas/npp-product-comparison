function [matchupStats,combinedModelAndObsNpp] = calculateMatchupStatistics(...
    nppInsituMonthlyMean,nppModelLocalMonthlyMean,labelModels,labelLocations,...
    filenameOutputLatexTableMatchupStats,filenameOutputCsvTableLocalNpp)

% CALCULATEMATCHUPSTATISTICS Computes regression statistics between modelled 
% and in situ NPP data and generate a .tex table for statistics outputs 
% and a .csv table for NPP values (modelled + in situ).

    nLocs = length(labelLocations);
    nNppModels = length(labelModels);
    nStats = 6; % number of statistics to compute
    
    % Initialise output arrays
    matchupStats = NaN(nLocs,nNppModels,nStats);
    combinedModelAndObsNpp = NaN(12,nNppModels+1,nLocs);
    
    for iLoc = 1:nLocs
        localInsituData = nppInsituMonthlyMean{:,iLoc}; % table

        for iModel = 1:nNppModels
            localModelData = nppModelLocalMonthlyMean(:,iModel,iLoc); % array

            % Filter out NaN observations and corresponding modelled data
            validIdx = ~isnan(localInsituData) & ~isnan(localModelData);
            localInsituDataValid = localInsituData(validIdx);
            localModelDataValid = localModelData(validIdx);

            % Compute matchup statistics
            [matchupStats(iLoc,iModel,:),labelStats] = computeMatchupStats(localInsituDataValid,localModelDataValid);

        end

        allLocalModelData = nppModelLocalMonthlyMean(:,:,iLoc);
        combinedModelAndObsNpp(:,:,iLoc) = [allLocalModelData, localInsituData]; % concatenate

    end

    % Generate LaTeX table for regression statistics
    generateLatexOutput(matchupStats,labelLocations,labelModels,labelStats,...
        filenameOutputLatexTableMatchupStats);

    % Generate CSV table for NPP data
    generateCsvOutput(combinedModelAndObsNpp,labelModels,labelLocations,...
        filenameOutputCsvTableLocalNpp);
  
end % calculateMatchupStatistics

% =========================================================================
%%
% -------------------------------------------------------------------------
% LOCAL FUNCTIONS USED IN THIS SCRIPT
% -------------------------------------------------------------------------

function [stats,labelStatNames] = computeMatchupStats(insituData, modelData)

    % Fit a linear model
    regressCoeff = polyfit(insituData, modelData, 1);
    slope = regressCoeff(1);

    % Correlation coefficient
    [corrCoeff,pvalue] = corr(insituData, modelData, 'Type', 'Pearson');
    rSquared = corrCoeff^2;
    
    % Error metrics
    [rmse,~] = calcRootMeanSquaredError(insituData,modelData); % greek letter: phi
    [me,~] = calcMeanError(insituData,modelData); % aka bias, greek letter: delta
    [mae,~] = calcMeanAbsoluteError(insituData,modelData);
    mape = calcMeanAbsolutePercentageError(insituData,modelData);

    % Return statistics
    labelStatNames = {'slope','$r$','$r^2$','RMSE','MAE','MAPE'};
    stats = [slope, corrCoeff, rSquared, rmse, mae, mape];
    
end % computeMatchupStats

% *************************************************************************

function generateLatexOutput(matchupStats,stationLabels,modelLabels,statLabels,...
    filenameOutputLatexTableStats)

    % Reshape misfit data into 2D for LaTeX table
    [nLocs,nModels,nStats] = size(matchupStats);
    misfitDataReshaped = NaN(nLocs,nModels*nStats);
    for iLoc = 1:nLocs
        localStats = [];
        for iModel = 1:nModels
            tempMatrix = squeeze(matchupStats(iLoc,iModel,:)); 
            localStats = [localStats;tempMatrix];
        end
        misfitDataReshaped(iLoc,:) = localStats;
    end

    % Transpose for LaTeX formatting
    misfitDataTransposed = misfitDataReshaped';

    % Call a custom function to generate the LaTeX table
    generateLatexTable(misfitDataTransposed,stationLabels,modelLabels,statLabels, ...
        fullfile('.','data','processed',filenameOutputLatexTableStats));
    
end % generateLatexOutput

% *************************************************************************

function generateCsvOutput(nppData,labelModels,labelLocations,filenameOutputCsvTable)

    % Reshape data for CSV
    [nMonths, nDataTypes, nLocs] = size(nppData);
    nppDataReshaped = reshape(nppData, [nMonths, nDataTypes*nLocs]);

    % Prepare headers
    firstHeaderRow = [{''},repmat(labelLocations(1),1,nDataTypes),...
                           repmat(labelLocations(2),1,nDataTypes),...
                           repmat(labelLocations(3),1,nDataTypes),...
                           repmat(labelLocations(4),1,nDataTypes)];            
    secondHeaderRow = [{''}, repmat([labelModels, {'14C'}], 1, nLocs)];

    % Combine headers and data
    csvContent = cell2table([...
        firstHeaderRow;...
        secondHeaderRow;...
        [{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'}',...
        num2cell(nppDataReshaped)]]);
    
    % Write table to CSV without column names
    writetable(csvContent,fullfile('.','data','processed',filenameOutputCsvTable),...
        'WriteVariableNames',false,'Delimiter',',');

end % generateCsvOutput

% *************************************************************************

function generateLatexTable(data,labelStations,labelModelNames,...
    labelStatisticNames,pathToFile)

    % data = tableMisfit_resh_trans;
    % pathToFile = fullfile('.','data','interim','latex_table_npp_coeffs.tex');
    nStats = numel(labelStatisticNames);
    nProds = numel(labelModelNames);

    % Open file for writing
    fid = fopen(pathToFile, 'w');
    fprintf(fid, '\\begin{table}[h]\n');
    fprintf(fid, '\\centering\n');
    fprintf(fid, '\\begin{tabular}{%s}\n', repmat('c', 1, size(data, 2)));
    fprintf(fid, '\\toprule\n');

    % Print column headers
    fprintf(fid, '& & %s & %s & %s & %s \\\\\n', labelStations{:});
    fprintf(fid, '\\midrule\n');

    % Print the data
    iRow = 0;
    for iProd = 1:nProds
        for iStat = 1:nStats

            % Update row
            iRow = iRow + 1;

            % Determine the row data
            rowData = data(iRow,:);

            % Format numbers based on value
            formattedRowData = cell(1, numel(rowData));
            for k = 1:numel(rowData)
                if abs(rowData(k)) >= 10
                    formattedRowData{k} = sprintf('%.0f', rowData(k));
                elseif (abs(rowData(k)) < 10 && abs(rowData(k)) >= 1)
                    formattedRowData{k} = sprintf('%.1f', rowData(k));
                else
                    formattedRowData{k} = sprintf('%.2f', rowData(k));
                end
            end

            % If the first statistic in the group
            if mod(iStat-1, nStats) == 0
                % Print a horizontal line before a new group if not the first group
                if iProd > 1
                    fprintf(fid, '\\cmidrule(lr){1-6}\n');
                end
                fprintf(fid, '%s & %s & %s \\\\\n', ...
                    labelModelNames{iProd}, ...
                    labelStatisticNames{iStat}, ...
                    sprintf('%s & ', formattedRowData{1:end-1}));
                fprintf(fid, '%s \\\\\n', formattedRowData{end});
            else
                fprintf(fid, '& %s & %s \\\\\n', ...
                    labelStatisticNames{iStat}, ...
                    sprintf('%s & ', formattedRowData{1:end-1}));
                fprintf(fid, '%s \\\\\n', formattedRowData{end});
            end
        end
    end

    fprintf(fid, '\\bottomrule\n');
    fprintf(fid, '\\end{tabular}\n');
    fprintf(fid, '\\end{table}\n');
    fclose(fid);

end % generateLatexTable

% *************************************************************************