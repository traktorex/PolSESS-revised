# Pol-SESS (revised generator)

A MATLAB generator of simulated two-speaker mixtures for speech separation and enhancement. Each mixture combines Polish and other read speech with an acoustic scene, a sound event and reverberation. Every layer is saved as its own time-aligned file next to the mixture, so a layer can be removed from the mixture by adding its phase-inverted copy (MM-IPC, mix modification by inverted phase cancellation).

This repository is a revision of the original Pol-SESS generator by Mariusz Kleć, [github.com/mklec/PolSESS](https://github.com/mklec/PolSESS). The original commit is kept in this repository's history. If you use the generator or data generated with it, please cite the original papers (below).

## What the revision changes

1. **Scene level.** The original generator added the background scene at its recorded level, usually far below the speech. The revised generator scales the scene so that its RMS level, relative to the two-speaker mixture, is drawn uniformly between −8 and +1 dB (`sceneToSpeechRange`). The drawn offset and gain are saved per mixture (`sceneRandomDB`, `sceneOffsetDB`, `sceneVolumeGain`).
2. **Speaker balance.** The Polish part of Multilingual LibriSpeech (MLS) is dominated by one reader. The revised source table, `dataSources_v3`, adds the French, Spanish, Italian and Portuguese parts of MLS and the English LibriSpeech clean subsets. In the training subset it allows at most 200 recordings per MLS reader and 50 per LibriSpeech reader.
3. **Data split.** The original table assigned the utterances of the Polish Read Speech corpus (PRS, the CLARIN `emu` corpus) to train / val / test one by one. The revised table assigns whole recording sessions, so the PRS split is disjoint by session. MLS and LibriSpeech keep their own corpora's partitions (MLS train / dev / test; LibriSpeech train-clean / dev-clean / test-clean).
4. **Indoor / outdoor runs.** `sceneTypeFilter` (`'indoor'`, `'outdoor'` or `'both'`) restricts a run to indoor scenes (which get reverberation) or outdoor scenes (which do not).
5. **Smaller fixes.** A speech recording no longer than the mixture is read whole and padded with silence on both sides. Reverberation parameter ranges are parsed once before the loop. The corpus metadata is also written as CSV.

## Speech sources in `dataSources_v3`

| `source` tag | corpus | train | val | test |
|---|---|---:|---:|---:|
| `emu` | PRS (CLARIN), sessions | 387 | 83 | 83 |
| `libriSpeech` | MLS, five languages, readers | 346 | 62 | 62 |
| `librispeech_clean` | LibriSpeech (English), readers | 251 | 40 | 40 |

Note: the tag `libriSpeech` (kept from the original table) means MLS, in all five languages. The English LibriSpeech is `librispeech_clean`.

Scenes come from WHAM! noise, TAU Urban Acoustic Scenes 2019 and TUT Acoustic Scenes 2017. Events come from ESC-50 and FSD50K. Events are matched to the scene class by `backgroundClassesMatch.mat`, which contains no human-voice classes, and reverberation ranges per scene class come from `reverbParamsForClasses.mat`.

## Files

| file | contents |
|---|---|
| `generatePolSESSInit.m` | the generator; its first section holds all settings |
| `mixSignals.m`, `generateReverb.m`, `detectClipping.m`, `removeClipping.m` | helpers called by the generator |
| `dataSources_v3.mat` | the source table with the split (MATLAB table `datasrc`) |
| `dataSources_v3.csv` | the same table as text |
| `backgroundClassesMatch.mat` / `.csv` | which event classes fit which scene class, and whether the scene is indoor or outdoor |
| `reverbParamsForClasses.mat` | reverberation parameter ranges per scene class |

## How to run

1. Download the source corpora. Their URLs are in the comments at the top of `generatePolSESSInit.m`.
2. Set the paths in the first section of `generatePolSESSInit.m`. The table stores paths relative to these roots, for example `\mls_french\train\audio\...` under the MLS root and `\LibriSpeech\train-clean-100\...` under the LibriSpeech root.
3. Set the output folder and name, `outputFreq` (8000 or 16000), `mixLength` (seconds, at least 4), `subset`, `sceneTypeFilter` and `howManyToGenerate`, then run the script in MATLAB. The script calls `reverberator` (Audio Toolbox) and `audioresample`.

The script writes the mixtures and their layers under `outputDir/theNameofDB/subset/`. It saves the metadata of every mixture (source files, offsets, levels, reverberation parameters) as `corpus_<name>_<subset>_final.mat` and `.csv`.

The corpus used in the DGSS-ASR paper (16 kHz, 4 s mixtures) was generated in six runs, one indoor and one outdoor run per subset:

| subset | indoor | outdoor |
|---|---:|---:|
| train | 64,000 | 64,000 |
| val | 6,400 | 6,400 |
| test | 6,400 | 6,400 |

File names are random and `rng('shuffle')` is used, so a rerun gives a different corpus drawn from the same table and split.

## Citation

M. Kleć, K. Szklanny and A. Wieczorkowska, "A solution for developing corpora for Polish speech enhancement in complex acoustic environments," in *Advances in Information Systems Development*, LNISO, Springer, 2025, pp. 125–143. doi:[10.1007/978-3-031-87880-0_7](https://doi.org/10.1007/978-3-031-87880-0_7)

M. Kleć, K. Szklanny and A. Wieczorkowska, "Developing a corpus for Polish speech enhancement by reducing noise, reverberation, and disruptions," in *Proc. ISD 2024*, Gdańsk, Poland, 2024. doi:[10.62036/ISD.2024.37](https://doi.org/10.62036/ISD.2024.37)

The source corpora keep their own licences; this repository distributes only file lists and parameters, not audio.

## License

MIT, see `LICENSE`.
