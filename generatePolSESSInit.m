% ######################################################################
% The script for generating simulated polish speech with noise,
% reverberation and disruptions for the purpose of Speech Enhancement
% If you use this script, please cite the following paper:
%
% Kleć, Mariusz, Krzysztof Szklanny, and Alicja Wieczorkowska.
% "A Solution for Developing Corpora for Polish Speech Enhancement in Complex Acoustic Environments", 2024.
%
% ######################################################################


%% define important constants for the absolute paths of downloaded data sources

% paths to speech corpora

% the absolute path to downloaded emu corpus: https://mowa.clarin-pl.eu/korpusy
emuDBPath = 'C:\datasety\clarin_emu';

% the path to downloaded multilingual LibriSpeech (only PL part): https://www.openslr.org/94/
libriSpeechPLDBPath = 'C:\datasety\mls';

% the path to downloaded LibriSpeech (English, clean subsets): https://www.openslr.org/12
libriSpeechENDBPath = 'C:\datasety\LibriMix\datasetyLibriMixdatasets';

% paths to environmental scenes corpora

% the path to WHAM  http://wham.whisper.ai/
whamNoiseDBPath = 'C:\datasety\wham_noise\wham_noise';

% the path to TUT 2027: https://zenodo.org/records/400515
tutDBPath = 'C:\datasety\TUT-acoustic-scenes-2017';

% the path to TAU-urban-acoustic-scenes
% please reorganize the data so that all of the recordings are stored in single audio
% directory!
tauDBPath = 'C:\datasety\TAU-urban-acoustic-scenes-2019-development';

% paths to sound events corpora

% the path to ESC50 events https://github.com/karolpiczak/ESC-50
esc50eDBPath = 'C:\datasety\ESC-50-master\audio';

% the path to FSD50K events https://zenodo.org/records/4060432
fsd50kDBPath = 'C:\datasety\FSD50K';

%% define other important information about the corpus

% the output where the generated corpus will be stored
outputDir = 'C:\datasety\';

% the name of the created corpus - it will be the name of the folder which
% stores the corpus
theNameofDB = 'PolSESS_C_final_128_v2_outdoor';

% the desired frequency of output files. Can be 8000 or 16000Hz
outputFreq = 8000;

% how long should be the generated files in seconds. Default: 4 seconds.
% Must not be less that as the files need to have at least this length
% so that the script can choose the fragment from it of this length.
mixLength = 4;

% declare how many files you want to generate for the current subset
howManyToGenerate = 6400;

% type one of these: test | val | train
% it denotes the subset you currently want to generate
subset = 'test';

% choose the type of scenes to include: 'indoor' | 'outdoor' | 'both'
% 'indoor' - only indoor scenes with reverberation
% 'outdoor' - only outdoor scenes without reverberation
% 'both' - mix of indoor and outdoor scenes
sceneTypeFilter = 'outdoor';

% the speech to speech ratio range when mixing two speakers
SSRrange = [-5 5];

% range of how much the scene will be quieter than the speech mix (in decibels)
% first value - the lowest volume of scene in relation to speech mix
% second value - the highest volume of scene in relation to speech mix
sceneToSpeechRange = [-8, 1];

%% here are some other constants that should not rather be changed

rng('shuffle');

% The names of generated files are 16 randomly choosen characters
s = 'abcdefghijklmnopqrstuvwxyz0123456789';
numRands = length(s);
sLength = 16;

% load the references to data sources. This file can be created using
% generateDataSources.mat
load('dataSources_v3.mat');

% load the classes of noises and events in the form of matrix which
% specifies which event class suits to which noise class
% (the matrix has % been manually prepared)
load('backgroundClassesMatch.mat');

% load the range of parameters for reverb that suits to the particular noise class
load('reverbParamsForClasses.mat');

%% data preprocessing and the initialization

% creating absolute paths to data sources

emu_only = datasrc(datasrc.source == "emu",:);
datasrc.filePath(datasrc.source=="emu") = cellfun(@(c)fullfile(emuDBPath,c),emu_only.filePath,'uni',false);

libri_only = datasrc(datasrc.source == "libriSpeech",:);
datasrc.filePath(datasrc.source=="libriSpeech") = cellfun(@(c)fullfile(libriSpeechPLDBPath,c),libri_only.filePath,'uni',false);

librispeech_clean_only = datasrc(datasrc.source == "librispeech_clean",:);
datasrc.filePath(datasrc.source=="librispeech_clean") = cellfun(@(c)fullfile(libriSpeechENDBPath,c),librispeech_clean_only.filePath,'uni',false);

wham_only = datasrc(datasrc.source == "wham",:);
datasrc.filePath(datasrc.source=="wham") = cellfun(@(c)fullfile(whamNoiseDBPath,c),wham_only.filePath,'uni',false);

tut_only = datasrc(datasrc.source == "tut",:);
datasrc.filePath(datasrc.source=="tut") = cellfun(@(c)fullfile(tutDBPath,c),tut_only.filePath,'uni',false);

tau_only = datasrc(datasrc.source == "tau",:);
datasrc.filePath(datasrc.source=="tau") = cellfun(@(c)fullfile(tauDBPath,c),tau_only.filePath,'uni',false);

esc50_only = datasrc(datasrc.source == "esc50",:);
datasrc.filePath(datasrc.source=="esc50") = cellfun(@(c)fullfile(esc50eDBPath,c),esc50_only.filePath,'uni',false);

fsd50_only = datasrc(datasrc.source == "fsd50",:);
datasrc.filePath(datasrc.source=="fsd50") = cellfun(@(c)fullfile(fsd50kDBPath,c),fsd50_only.filePath,'uni',false);

% create the main dir for the DB
if(~exist(fullfile(outputDir,theNameofDB),'dir'))
    mkdir(fullfile(outputDir,theNameofDB));
end

% create the folders for subset
if(~exist(fullfile(outputDir,theNameofDB,subset),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset));
end

% create subfolders for storing components of the mixes

% here, there will be stored the clean speech
if(~exist(fullfile(outputDir,theNameofDB,subset,'clean'),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset,'clean'));
end

% this folder is intended to store the final mixes
if(~exist(fullfile(outputDir,theNameofDB,subset,'mix'),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset,'mix'));
end

% this folder is for storing sounds of audio scenes
if(~exist(fullfile(outputDir,theNameofDB,subset,'scene'),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset,'scene'));
end

% this folder stores the sound of events
if(~exist(fullfile(outputDir,theNameofDB,subset,'event'),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset,'event'));
end

% these folders store the sound of reverberation
if(~exist(fullfile(outputDir,theNameofDB,subset,'ev_reverb'),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset,'ev_reverb'));
end

if(~exist(fullfile(outputDir,theNameofDB,subset,'sp1_reverb'),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset,'sp1_reverb'));
end

if(~exist(fullfile(outputDir,theNameofDB,subset,'sp2_reverb'),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset,'sp2_reverb'));
end

% select the given subset from data sources
data = datasrc(datasrc.subset == subset,:);

% select the sources of speech from given subset
data_speech = data(data.role == 'speech',:);

% select the sources of scenes from given subset
data_scene = data(data.role == 'envScene',:);

% pre-filter scenes by indoor/outdoor to avoid wasted iterations
if ~strcmp(sceneTypeFilter, 'both')
    sceneKeep = false(height(data_scene), 1);
    for si = 1:height(data_scene)
        isIndoor = (backgroundClasses.(string(data_scene.class(si)))(2) == "in");
        sceneKeep(si) = strcmp(sceneTypeFilter, 'indoor') == isIndoor;
    end
    data_scene = data_scene(sceneKeep, :);
end

% select the sources of events from given subset
data_event = data(data.role == 'events',:);

% the size of each data source type
sizeSpeech = size(data_speech,1);
sizeScene = size(data_scene,1);
sizeEvent = size(data_event,1);

% the matlab table which will be storing all the metadata about generating
% corpus
corpus = table('Size',[howManyToGenerate, 34],...
    'VariableNames',{'subset',	'speech1OryginalPath', 'speech1Start','speech1End',	'speech2OryginalPath', ...
    'speech2Start','speech2End','SSR',	'sceneOryginalPath','sceneStart','sceneEnd','sceneRandomDB','sceneOffsetDB','sceneVolumeGain','eventOryginalPath','eventStart','eventEnd','speaker1File', ...
    'speaker2File',	'eventFile',	'sceneFile', ...
    'reverbForSpeaker1',	'reverbForSpeaker2',	'reverbForEvent', ...
    'mixFile',	'sceneClass',	'eventClass', 'preDelayForEvent','preDelay1','preDelay2', ...
    'highCut',	'diffusion',	'decay',	'freqDamp'}, ...
    'VariableTypes',{'string','string','double','double','string','double','double','double','string','double','double','double','double','double','string','double','double','string',...
    'string','string','string','string','string','string','string',...
    'string','string','double','double','double','double','double','double','double'});

% structure for reverb settings
processedReverbSettings = struct();
for i = 1:height(reverbSettings)
    rawClassName = string(reverbSettings.sceneClass(i));
    className = matlab.lang.makeValidName(rawClassName);
    processedReverbSettings.(className).preDelay = str2double(split(string(reverbSettings.preDelay(i))));
    processedReverbSettings.(className).highCut = str2double(split(string(reverbSettings.highCut(i))));
    processedReverbSettings.(className).diffusion = str2double(split(string(reverbSettings.diffusion(i))));
    processedReverbSettings.(className).decay = str2double(split(string(reverbSettings.decay(i))));
    processedReverbSettings.(className).freqDamp = str2double(split(string(reverbSettings.freqDamp(i))));
end

%% data generation

id = 1;
while id <= howManyToGenerate

    where = 'in'; % the variable that keeps whether the speech is indoor or not.


    % randomly choose speaker 1 source
    randSpeech1 = randi(sizeSpeech);
    speaker1Path = string(data_speech.filePath(randSpeech1));
    speaker1Duration = data_speech.duration(randSpeech1);
    speaker1SampleRate = data_speech.sampleRate(randSpeech1);
    speaker1Channels = data_speech.channels(randSpeech1);

    % randomly choose speaker 2 source
    randSpeech2 = randi(sizeSpeech);
    speaker2Path = string(data_speech.filePath(randSpeech2));
    speaker2Duration = data_speech.duration(randSpeech2);
    speaker2SampleRate = data_speech.sampleRate(randSpeech2);
    speaker2Channels = data_speech.channels(randSpeech2);

    % it they are the same, continue selection with other file...
    if(randSpeech2 == randSpeech1)
        continue;
    end

    % randomly choose the sources of scene
    randScene = randi(sizeScene);
    scenePath = string(data_scene.filePath(randScene));
    sceneDuration = data_scene.duration(randScene);
    sceneSampleRate = data_scene.sampleRate(randScene);
    sceneChannels = data_scene.channels(randScene);
    sceneClass = data_scene.class(randScene);

    % next, the event should suit to the scene class. Here, the matrix with
    % scene and event classes is utilized...

    % chosing non empty indexes from the matrix of the scene class column
    idcl = ~cellfun(@isempty,string(backgroundClasses.(string(sceneClass))));

    % filter the eventClass that suits to the scene class and randomly
    % choose one of the class
    suitEC = rmmissing(backgroundClasses.eventClass(idcl));
    choosenEventClass = suitEC(randi(size(suitEC,1)));

    % now randomly chosing the event which contains given class (it should
    % already suit to the scene class)
    foundECIdxs = cell2mat(cellfun(@(c)contains(c,choosenEventClass),string(data_event.class),'uni',false));
    suitableEvents = data_event(foundECIdxs,:);

    % just in case...
    if(isempty(suitableEvents))
        continue
    end

    % randomly choosing the event from those that suits to the scene class
    randEvent = randi(size(suitableEvents,1));
    eventPath = string(suitableEvents.filePath(randEvent));
    eventDuration = suitableEvents.duration(randEvent);
    eventSampleRate = suitableEvents.sampleRate(randEvent);
    eventChannels = suitableEvents.channels(randEvent);

    % now randomly select the given audio fragment (mixLenght) from each of each the
    % component' file (assuming the the component's file are longer than
    % mixLength)

    speech1samples = speaker1Duration * speaker1SampleRate;
    speaker1segmentL = speaker1SampleRate * mixLength;
    if speech1samples > speaker1segmentL
        speaker1segmentStart = randi(ceil(speech1samples - speaker1segmentL));
        speaker1segmentEnd = speaker1segmentStart + speaker1segmentL - 1;
        [ySpeech1, fsSpeech1] = audioread(speaker1Path,[speaker1segmentStart,speaker1segmentEnd]);
    else
        % recording is <= mixLength: read the whole file, pad symmetrically with silence
        [ySpeech1, fsSpeech1] = audioread(speaker1Path);
        padTotal = speaker1segmentL - size(ySpeech1, 1);
        padBefore = floor(padTotal / 2);
        padAfter = padTotal - padBefore;
        ySpeech1 = [zeros(padBefore, size(ySpeech1, 2)); ySpeech1; zeros(padAfter, size(ySpeech1, 2))];
        speaker1segmentStart = 1;
        speaker1segmentEnd = round(speech1samples);
    end


    speech2samples = speaker2Duration * speaker2SampleRate;
    speaker2segmentL = speaker2SampleRate * mixLength;
    if speech2samples > speaker2segmentL
        speaker2segmentStart = randi(ceil(speech2samples - speaker2segmentL));
        speaker2segmentEnd = speaker2segmentStart + speaker2segmentL - 1;
        [ySpeech2, fsSpeech2] = audioread(speaker2Path,[speaker2segmentStart,speaker2segmentEnd]);
    else
        % recording is <= mixLength: read the whole file, pad symmetrically with silence
        [ySpeech2, fsSpeech2] = audioread(speaker2Path);
        padTotal = speaker2segmentL - size(ySpeech2, 1);
        padBefore = floor(padTotal / 2);
        padAfter = padTotal - padBefore;
        ySpeech2 = [zeros(padBefore, size(ySpeech2, 2)); ySpeech2; zeros(padAfter, size(ySpeech2, 2))];
        speaker2segmentStart = 1;
        speaker2segmentEnd = round(speech2samples);
    end


    sceneSamples = sceneDuration * sceneSampleRate;
    sceneSegmentL = sceneSampleRate * mixLength;
    sceneSegmentStart = randi(ceil(sceneSamples - sceneSegmentL));
    sceneSegmentEnd = sceneSegmentStart + sceneSegmentL-1;
    [yScene, fsScene] = audioread(scenePath,[sceneSegmentStart,sceneSegmentEnd]);


    eventSamples = eventDuration * eventSampleRate;
    eventSegmentL = eventSampleRate * mixLength;
    eventSegmentStart = randi(ceil(eventSamples - eventSegmentL));
    eventSegmentEnd = eventSegmentStart + eventSegmentL-1;
    [yEvent, fsEvent] = audioread(eventPath,[eventSegmentStart,eventSegmentEnd]);

    % convert to mono if the components are in stereo

    if(speaker1Channels == 2)
        ySpeech1 = (ySpeech1(:,1)+ySpeech1(:,2))/2;
    end

    if(speaker2Channels == 2)
        ySpeech2 = (ySpeech2(:,1)+ySpeech2(:,2))/2;
    end

    if(sceneChannels == 2)
        yScene = (yScene(:,1)+yScene(:,2))/2;
    end

    if(eventChannels == 2)
        yEvent = (yEvent(:,1)+yEvent(:,2))/2;
    end

    % in the case where there has been empty fragment of event
    if(sum(yEvent~=0)==0)
        continue
    end

    % resample to desired outputFrequency

    if(fsSpeech1 ~= outputFreq)
        ySpeech1 = audioresample(ySpeech1,InputRate=fsSpeech1,OutputRate=outputFreq);
        fsSpeech1 = outputFreq;
    end

    if(fsSpeech2 ~= outputFreq)
        ySpeech2 = audioresample(ySpeech2,InputRate=fsSpeech2,OutputRate=outputFreq);
        fsSpeech2 = outputFreq;
    end

    if(fsScene ~= outputFreq)
        yScene = audioresample(yScene,InputRate=fsScene,OutputRate=outputFreq);
        fsScene = outputFreq;
    end

    if(fsEvent ~= outputFreq)
        yEvent = audioresample(yEvent,InputRate=fsEvent,OutputRate=outputFreq);
        fsEvent = outputFreq;
    end

    % remove clipping if any, just in case...
    ySpeech1 = removeClipping(ySpeech1);
    ySpeech2 = removeClipping(ySpeech2);
    yScene = removeClipping(yScene);
    yEvent = removeClipping(yEvent);

    % randomly select the speech to speech ratio and mix the speech
    speechRatio = randi(SSRrange);
    [speechMix,ySpeech1,ySpeech2] = mixSignals(ySpeech1,ySpeech2,speechRatio);
    ySpeech2 = removeClipping(ySpeech2);
    speechMix = removeClipping(speechMix);

    clippingExists = detectClipping(speechMix);

    if(clippingExists)
        disp('CLIPPING continue...');
        continue
    end

    % now the scene volume will be adjusted to be quieter than the speech mix.
    % the range of possible differences in volume between scene and speech mix is
    % defined in sceneToSpeechRange variable. i.e. if sceneToSpeechRange = [-14,0]
    % then the scene will be between 0 and 14 dB quieter than the speech mix.

    % calculate RMS of scene and speechMix 
    speechRMS = sqrt(mean(speechMix.^2));
    sceneRMS = sqrt(mean(yScene.^2));

    % Desired offset (first value in sceneToSpeechRange indicates how much 
    % the scene will be quieter than the speech mix)
    sceneTargetOffsetDB = sceneToSpeechRange(1);

    % randomize within the range
    sceneRandomDB = (sceneToSpeechRange(2) - sceneToSpeechRange(1))*rand();

    % Total desired offset
    totalSceneOffsetDB = sceneTargetOffsetDB + sceneRandomDB;

    % Calculate target scene RMS
    targetSceneRMS = speechRMS * 10^(totalSceneOffsetDB/20);

    % Calculate gain
    if sceneRMS > 0
        sceneGain = targetSceneRMS / sceneRMS;
    else
        sceneGain = 1; % avoid division by zero
    end

    % Apply gain to scene
    yScene = yScene * sceneGain;

    % next, check if the scene class is indoor or not. If indoor than apply
    % reverberation to the speech and events. In such a case the speech and
    % events will have the same reverberation parameters, except the first replection time.

    % check if scene is indoor or not
    where = backgroundClasses.(string(sceneClass))(2);

    % apply scene type filter
    if strcmp(sceneTypeFilter, 'indoor') && where ~= "in"
        continue; % skip outdoor scenes if only indoor is requested
    elseif strcmp(sceneTypeFilter, 'outdoor') && where == "in"
        continue; % skip indoor scenes if only outdoor is requested
    end
    % if sceneTypeFilter is 'both', accept all scenes

    % than apply reverberation for only indoor classes
    if(where == "in")

        % Sanitize the sceneClass name to match the struct field name
        validSceneClass = matlab.lang.makeValidName(string(sceneClass));

        % just in case...
        if(~isfield(processedReverbSettings, validSceneClass))
            continue
        end

        % read the pre-processed reverb settings directly from the struct
        rset = processedReverbSettings.(validSceneClass);

        % randomly choosing the reverb parameters from the pre-computed ranges
        
        % Pre-delay
        tpd2 = rset.preDelay;
        delshift = rand*(tpd2(2)-tpd2(1));
        preDelay1 = tpd2(1) + delshift;
        preDelay2 = preDelay1 - ((delshift) * (rand*0.3));

        % Lowpass filter cutoff
        thc2 = rset.highCut;
        highCut = thc2(1) + rand*(thc2(2)-thc2(1));

        % Diffusion
        tdif2 = rset.diffusion;
        diffusion = tdif2(1) + rand*(tdif2(2)-tdif2(1));

        % Decay
        tde2 = rset.decay;
        decay = tde2(1) + rand*(tde2(2)-tde2(1));

        % HighFrequencyDamping
        tfe2 = rset.freqDamp;
        freqDamp =  tfe2(1) + rand*(tfe2(2)-tfe2(1));

        % generate fully wet reverb for speech

        [reverbForSpeaker1] = generateReverb(ySpeech1,outputFreq,preDelay1,highCut,diffusion,decay,freqDamp,1);
        [reverbForSpeaker2] = generateReverb(ySpeech2,outputFreq,preDelay2,highCut,diffusion,decay,freqDamp,1);
        reverbForSpeaker1 = removeClipping(reverbForSpeaker1);
        reverbForSpeaker2 = removeClipping(reverbForSpeaker2);

        % generate reverb for event
        preDelayForEvent = tpd2(1) + rand*(tpd2(2)-tpd2(1));
        [reverbForEvent] = generateReverb(yEvent,outputFreq,preDelayForEvent,highCut,diffusion,decay,freqDamp,1);
        reverbForEvent = removeClipping(reverbForEvent);

        % do the mix of scene with sound event with all the reverberations
        % (also for speakers)
        mixBackground = yScene + yEvent + reverbForEvent + reverbForSpeaker1 + reverbForSpeaker2;

        % do the mix of background and speech + reverb for speech
        mixAll = mixBackground + speechMix;

        clippingExists = detectClipping(mixAll);
        if(clippingExists)
            disp('CLIPPING continue...');
            continue
        end

    else % when the scene class in outdoor then there is no reverb

        % do the mix of scene with sound event
        mixBackground = yEvent + yScene;

        % do the mix of background and speech
        mixAll = mixBackground + speechMix;

        clippingExists = detectClipping(mixAll);
        if(clippingExists)
            disp('CLIPPING continue...');
            continue
        end

    end




    % generating names for storing files

    speaker1File = s(ceil(rand(1,sLength)*numRands));
    speaker2File = s(ceil(rand(1,sLength)*numRands));

    eventFile = s(ceil(rand(1,sLength)*numRands));
    sceneFile = s(ceil(rand(1,sLength)*numRands));
    reverbFile = s(ceil(rand(1,sLength)*numRands));

    if(where == "in")
        noiseAllFile = [sceneFile '-' eventFile '-' reverbFile];
    else
        noiseAllFile = [sceneFile '-' eventFile];
    end

    mixFile = [speaker1File '-' speaker2File '-' noiseAllFile];

    % adding extentions to file names
    speaker1FileName = [speaker1File '.wav'];
    speaker2FileName = [speaker2File '.wav'];
    sceneFileName = [sceneFile '.wav'];
    eventFileName = [eventFile '.wav'];
    reverbForSpeaker1File = ['sp1_' reverbFile '.wav'];
    reverbForSpeaker2File = ['sp2_' reverbFile '.wav'];
    reverbForEventFile = ['ev_' reverbFile '.wav'];
    mixFileName = [mixFile '.wav'];

    % adding information to metadata file
    corpus.subset(id) = string(subset);
    corpus.speech1OryginalPath(id) = speaker1Path;
    corpus.speech1Start(id) = speaker1segmentStart;
    corpus.speech1End(id) = speaker1segmentEnd;
    corpus.speech2OryginalPath(id) = speaker2Path;
    corpus.speech2Start(id) = speaker2segmentStart;
    corpus.speech2End(id) = speaker2segmentEnd;
    corpus.sceneOryginalPath(id) = string(scenePath);
    corpus.sceneStart(id) = sceneSegmentStart;
    corpus.sceneEnd(id) = sceneSegmentEnd;
    corpus.sceneRandomDB(id) = sceneRandomDB;
    corpus.sceneOffsetDB(id) = totalSceneOffsetDB;
    corpus.sceneVolumeGain(id) = sceneGain;
    corpus.eventOryginalPath(id) = string(eventPath);
    corpus.eventStart(id) = eventSegmentStart;
    corpus.eventEnd(id) = eventSegmentEnd;

    corpus.speaker1File(id) = string(speaker1FileName);
    corpus.speaker2File(id) = string(speaker2FileName);
    corpus.SSR(id) = speechRatio;
    corpus.eventFile(id) = string(eventFileName);
    corpus.sceneFile(id) = string(sceneFileName);
    corpus.mixFile(id) = string(mixFileName);
    if(where == "in")
        corpus.reverbForSpeaker1(id) = string(reverbForSpeaker1File);
        corpus.reverbForSpeaker2(id) = string(reverbForSpeaker2File);
        corpus.reverbForEvent(id) = string(reverbForEventFile);
    else
        corpus.reverbForSpeaker1(id) = missing;
        corpus.reverbForSpeaker2(id) = missing;
        corpus.reverbForEvent(id) = missing;
    end

    corpus.sceneClass(id) = string(sceneClass);
    corpus.eventClass(id) = string(choosenEventClass);

    if(where == "in")
        corpus.preDelayForEvent(id) = preDelayForEvent;
        corpus.preDelay1(id) = preDelay1;
        corpus.preDelay2(id) = preDelay2;
        corpus.highCut(id) = highCut;
        corpus.diffusion(id) = diffusion;
        corpus.decay(id) = decay;
        corpus.freqDamp(id) = freqDamp;
    else
        corpus.preDelayForEvent(id) = NaN;
        corpus.preDelay1(id) = NaN;
        corpus.preDelay2(id) = NaN;
        corpus.highCut(id) = NaN;
        corpus.diffusion(id) = NaN;
        corpus.decay(id) = NaN;
        corpus.freqDamp(id) = NaN;
    end

    % save speaker 1
    audiowrite(fullfile(outputDir,theNameofDB,subset,'clean',speaker1FileName),ySpeech1,outputFreq);

    % save speaker 2
    audiowrite(fullfile(outputDir,theNameofDB,subset,'clean',speaker2FileName),ySpeech2,outputFreq);

    % save mix
    audiowrite(fullfile(outputDir,theNameofDB,subset,'mix',mixFileName),mixAll,outputFreq);

    % save scene
    audiowrite(fullfile(outputDir,theNameofDB,subset,'scene',sceneFileName),yScene,outputFreq);

    % save event
    audiowrite(fullfile(outputDir,theNameofDB,subset,'event',eventFileName),yEvent,outputFreq);

    % save reverb
    if(where == "in")
        audiowrite(fullfile(outputDir,theNameofDB,subset,'sp1_reverb',reverbForSpeaker1File),reverbForSpeaker1,outputFreq);
        audiowrite(fullfile(outputDir,theNameofDB,subset,'sp2_reverb',reverbForSpeaker2File),reverbForSpeaker2,outputFreq);
        audiowrite(fullfile(outputDir,theNameofDB,subset,'ev_reverb',reverbForEventFile),reverbForEvent,outputFreq);
    end

    % temporary save the metadata file at every 10000 files, as a backup
    if(mod(id,10000)==0)
        save(['corpus_' theNameofDB '_' num2str(id) '_' subset '_backup.mat'],'corpus');
    end

    disp(num2str(id));

    id = id + 1;
end

%% save the final created metadata file to disc
save(['corpus_' theNameofDB '_' subset '_final.mat'],'corpus');
writetable(corpus, ['corpus_' theNameofDB '_' subset '_final.csv']);