Here are the instructions on how to store 35t data files onto tape:

> kinit
> kx509
> setup sam_web_client
> setup lbnecode v<version> -q<qualifiers>
> cd your-working-area
(This is where you have the root files)

> cp <path>/example.json .
(where <path> points to the directory containing lbneutil/dhtools scripts and files.
  Now you have an example .json file in your directory).

> <path>/make_json_lbne.sh example.json
(This is to create all json files for all your root files in this directory)

> rm example.json
(Please remove the example.json before you declare the real .json files)

> <path>/declare_files.sh
(Now you declared all the .json files to SAM)

> cp *.root /lbne/data2/lbnepro/dropbox/data/
(copy all these root files to the dropbox)
or use the other dropboxes:

/pnfs/lbne/scratch/lbnepro/dropbox/data/
/lbne/data/lbnepro/dropbox/

The dropboxes on BlueArc have limited space.

Now you are done. The files in the dropbox will be picked up by FTS (File Transfer
Service) and to be stored onto both tapes and dCache disk through SAM.
