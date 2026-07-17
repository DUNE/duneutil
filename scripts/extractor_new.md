## extractor_new examples

### from a jobscript example

For a larsoft file

~~~
python extractor_new.py --infile=$outFile1 --appversion=$DUNE_VERSION \
 --appname=${APP_TAG}  --appfamily=larsoft --no_crc \
 --inputDidsFile=justin-input-dids.txt  --data_tier='full-reconstructed' \
 --file_format='artroot' --fcl_file=${FCL_FILE_NAME} \
 --namespace=${NAMESPACE} 
~~~
{: ..language-bash}

For a generic root file

~~~
python ${INPUT_TAR_DIR_LOCAL}/${DIRECTORY}/extractor_new.py \
--infile=$outFile2 --appversion=$DUNE_VERSION   --appname=${APP_TAG} \
--appfamily=larsoft --no_crc --inputDidsFile=justin-input-dids.txt \
--data_tier='root-tuple' --file_format='root' --fcl_file=${FCL_FILE_NAME} \
--no_extract --input_json=${PWD}/${oldjson} --namespace=${NAMESPACE} 
~~~
{: ..language-bash}


## standalone running

make certain you know the dids for the parents of your file and put in parent_dids.txt, otherwise it will guess the namespace for them as art only records the names.

right now this only works if you have a local path (no root:...)

~~~
python ~/extractor_new.py \
--infile=/pnfs/dune/persistent/staging/fardet-hd/29/a0/atmnu_max_weighted_randompolicy_dune10kt_1x2x6_50542214_117_20231201T220548Z_gen_g4_detsim_hitreco_20260626T114201Z_reco2.root \
--namespace=schellma --appname=reco2 --inputDidsFile=parent_dids.txt
~~~
{: ..language-bash}


yields

~~~
{
    "created_by": "schellma",
    "metadata": {
        "art.first_event": 11701,
        "art.last_event": 11800,
        "core.application.family": "art",
        "core.application.name": "reco2",
        "core.application.version": "v10_20_06",
        "core.data_stream": "out1",
        "core.data_tier": "full-reconstructed",
        "core.end_time": 1782475089.0,
        "core.event_count": 100,
        "core.file_content_status": "good",
        "core.file_format": "artroot",
        "core.file_type": "mc",
        "core.first_event_number": 11701,
        "core.group": "dune",
        "core.last_event_number": 11800,
        "core.run_type": "fardet-hd",
        "core.runs": [
            50542214
        ],
        "core.runs_subruns": [
            5054221400001
        ],
        "core.start_time": 1782474180.0,
        "dune.config_file": "unknown",
        "retention.class": "user",
        "retention.status": "active"
    },
    "name": "atmnu_max_weighted_randompolicy_dune10kt_1x2x6_50542214_117_20231201T220548Z_gen_g4_detsim_hitreco_20260626T114201Z_reco2.root",
    "namespace": "schellma",
    "parents": [
        {
            "name": "atmnu_max_weighted_randompolicy_dune10kt_1x2x6_50542214_117_20231201T220548Z_gen_g4_detsim_hitreco.root",
            "namespace": "fardet-hd"
        }
    ],
    "size": 820459690
}
~~~
{: ..language-json}