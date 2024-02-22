% Add all subfolders to the path
addpath(genpath('.'));

% Directory where the audio files are stored
sDir = '../data/audios/';

% Path to the CSV file
csvFilePath = '../data/audios/audio_features/audio_features.csv';

% Initialize an array to hold the paths of already processed audio files
processedFiles = [];

% Check if audio_features.csv exists
if exist(csvFilePath, 'file')
    % Read the existing CSV file
    existingTable = readtable(csvFilePath);
    % Extract the paths of already processed audio files
    processedFiles = existingTable.AudioPath;
end

% List all WAV files in the directory
audioFiles = dir(fullfile(sDir, '*.wav'));

% Filter files based on the length of the "Y" part and whether they have been processed
filteredFiles = [];
for i = 1:length(audioFiles)
    % Split filename into parts
    fileNameParts = split(audioFiles(i).name, '_');
    
    % Construct full path for comparison
    fullPath = fullfile(sDir, audioFiles(i).name);
    
    % Check if the second element has a length of 2 and if it has not been processed
    if length(fileNameParts{2}) == 2 && ~ismember(fullPath, processedFiles)
        filteredFiles = [filteredFiles, audioFiles(i)];
    end
end

% Update audioFiles to contain only the files you want to process
audioFiles = filteredFiles;

% Preallocate table for results
resultsTable = existingTable;

% Iterate through each audio file
for iFile = 1:length(audioFiles)
    % Display progress
    disp(['Processing file ' num2str(iFile) ' of ' num2str(length(audioFiles))]);
    disp("File: " + audioFiles(iFile).name);
    sFile = fullfile(sDir, audioFiles(iFile).name);
    [vSignal, iFs] = audioread(sFile);

    % Normalization
    vSignal = vSignal / max(abs(vSignal));

    % Parameters
    iFrame = ceil(40e-3 * iFs);
    iOverlap = floor(0.5 * iFrame);

    %% Features extraction for each file
    [vJitter, vShimmer] = JitterShimmer(vSignal, iFs);
    vFluctuation = Fluctuation(vSignal, iFs);
    vAdditiveNoise = AdditiveNoise(vSignal, iFs, iFrame, iOverlap);

    % Concatenate all features into a single row
    featureRow = [vJitter, vFluctuation, vAdditiveNoise];

    % Append to the results table
    newRow = {sFile, featureRow(1), featureRow(2), featureRow(3), featureRow(4), featureRow(5), ...
              vShimmer(1), vShimmer(2), vShimmer(3), vShimmer(4), ...
              featureRow(6), featureRow(7), featureRow(8), featureRow(9), ...
              featureRow(10), featureRow(11), featureRow(12), featureRow(13)};
    tempTable = cell2table(newRow, 'VariableNames', {'AudioPath', 'JITA', 'rJitter', 'RAP', 'rPPQ', 'rSPPQ', ...
                                                     'ShimmerDb', 'Shimmer', 'rAPQ', 'rSAPQ', ...
                                                     'FTRI', 'ATRI', 'FFTR', 'FATR', ...
                                                     'Nne', 'Hnr', 'CHNR', 'GNE'});
    resultsTable = [resultsTable; tempTable];

    if iFile % 10 == 0
        % Save the table to a CSV file
        writetable(resultsTable, '../data/audios/audio_features/audio_features.csv');
    end

end

