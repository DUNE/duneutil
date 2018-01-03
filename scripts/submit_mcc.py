#!/usr/bin/env python

import argparse
import logging
import os
import sys
import json
import subprocess
import time
from datetime import datetime
from ECLAPI import ECLConnection, ECLEntry

ECL_URL="http://dbweb6.fnal.gov:8080/ECL/dunepro"
now = datetime.now().strftime('%Y%m%d%H%M%S')

try:
    from cStringIO import StringIO      # Python 2
except ImportError:
    from io import StringIO

# set up the logger
log_stream = StringIO()    
FORMAT = '%(asctime)s - submit_mcc.py - %(levelname)s - %(message)s'
logging.basicConfig(stream=log_stream, level=logging.INFO, format=FORMAT)

def call_project_py(xml, stg, act, test=False):
    if test:
        tmpdir = "/pnfs/dune/scratch/dunepro/mcc10_test/test_{}".format(now)
        subprocess.call("mkdir -p {}".format(tmpdir), shell=True)
        overrides = ["wrap_proj", "-Onumevents=10",
                "-Ostage.numjobs=1", "-Ostage.outdir={tmp}",
                "-Ostage.workdir={tmp}".format(tmp=tmpdir)]
        logging.info("Submitting a test job with:")
        logging.info("                   numberjobs = 1;")
        logging.info("                   numevents  = 1;")
        logging.info("                   outdir  = {};".format(tmpdir))
        logging.info("                   workdir = {};".format(tmpdir))
    else:
        overrides = []
    prj_cmd = overrides + ["project.py", "--xml", xml, "--stage", stg,
        "--{}".format(act)]
    try:
        prj_out = subprocess.check_output(prj_cmd, stderr=subprocess.STDOUT)
        logging.info("project.py was run successfully.")
        logging.info("project.py output: {}".format(prj_out))
    except subprocess.CalledProcessError, e:
        logging.error("project.py exit with {}.".format(e.returncode))
        logging.error("project.py output: {}.".format(e.output))
        logging.error("Exiting now!")
        print(log_stream.getvalue())
        sys.exit(40)
    return

def handle_stage(workflow_def, xml, workflow, stage, nocheck=False, test=False):
    wf_dict = json.load(open(workflow_def))
    workflows = wf_dict["workflows"]
    if workflow not in workflows:
        logging.error("Workflow chosen is not defined in the json file.")
        print(log_stream.getvalue())
        sys.exit(30)
    if stage not in workflows[workflow]["stages"]:
        logging.error("Stage is not defined in the workflow.")
        print(log_stream.getvalue())
        sys.exit(31)
    stages = workflows[workflow]["stages"]
    actions = workflows[workflow]["actions"]
    stage_index = stages.index(stage)
    action = actions[stage_index]
    # not checking on previous stage if:
    #   1) '--no-check' is enabled;
    #   2) '--test' is enabled, cannot check on test jobs since xml file is 
    #       generated on the fly with parameter overrides;
    #   3) if the stage is the first stage of a workflow.
    if stage_index == 0 or test:
        nocheck=True
    if not nocheck:
        prev_stage = stages[stage_index-1]
        logging.info("Checking previous stage: {}".format(prev_stage))
        call_project_py(xml, prev_stage, "check")
        time.sleep(10)
    logging.info("Handle stage: {} with action: {}".format(stage, action))
    call_project_py(xml, stage, action, test)
    return

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='')
    groupArg = parser.add_argument_group('require arguments')

    groupArg.add_argument('--xml', metavar='xml_file', type=str, 
            help='path to xml file for project.py with path', required = True)
    groupArg.add_argument('--workflow', metavar='MCC_workflow_name', type=str,
            help='MCC workflow name', required = True)
    groupArg.add_argument('--stage', metavar='stage_name', type=str,
            help='stage name for project.py', required = True)

    parser.add_argument('--test', action='store_true',
            help='submit test jobs only')
    parser.add_argument('--no-check', action='store_true',
            help='turn off checking on previous stage')
    parser.add_argument('--workflow-def', type=str, default="workflows.json",
            metavar='workflow_definition_json_file',
            help='path to json file which defines the workflows')
    parser.add_argument('--post-ecl', action='store_true',
            help='post the output to ECL')
    parser.add_argument('--ecl-user', type=str, default="dunepro",
            help='ECL user')
    parser.add_argument('--ecl-password', type=str, help='ECL user password')
    parser.add_argument('--ecl-subject', type=str,
            default="MCC Submission Entry Subject",
            help='ECL entry subject name')
    parser.add_argument('--ecl-category', type=str,
            default="mcc10", help='ECL category name')
    parser.add_argument('--ecl-comment', type=str,
            default="submit_mcc.py entry comment", help='ECL entry comment')

    args = parser.parse_args()
    cwd = os.getcwd()

    logging.info("Current dir   : {}".format(cwd))
    logging.info("XML file used : {}".format(args.xml))
    logging.info("Workflow json : {}".format(args.workflow_def))
    logging.info("Workflow name : {}".format(args.workflow))
    logging.info("Stage name    : {}".format(args.stage))

    if not os.path.isfile(args.workflow_def):
        logging.error("Workflow definition file is not existed. Exit now!")
        print(log_stream.getvalue())
        sys.exit(11)
    if not os.path.isfile(args.xml):
        logging.error("XML file for project py is not existed. Exit now!")
        print(log_stream.getvalue())
        sys.exit(12)

    if args.test:
        logging.warn("Submitting testing jobs")
    if args.no_check:
        logging.warn("Will not check previous stage with project.py")
    if args.post_ecl:
        logging.info("Will make an ECL entry in dunepro ECL.")
        if not args.ecl_password:
            logging.error("ECL user password must be supplied. Exiting now!")
            print(log_stream.getvalue())
            sys.exit(20)

    # do submit_stage work here
    handle_stage(args.workflow_def, args.xml, args.workflow, args.stage,
            args.no_check, args.test)

    if args.post_ecl:
        ecl_entry = ECLEntry(
                category=args.ecl_category,
                tags=['MCCSubmission'],
                formname='MCC Submission',
                preformatted=False)
    
        logging.info("ECL subject    : {}".format(args.ecl_subject))

        ecl_entry.addSubject(args.ecl_subject)
        ecl_entry.setValue(name="work_dir", value=cwd)
        ecl_entry.setValue(name="xml_file", value=args.xml)
        ecl_entry.setValue(name="workflow_file", value=args.workflow_def)
        ecl_entry.setValue(name="workflow", value=args.workflow)
        ecl_entry.setValue(name="stage", value=args.stage)
        ecl_entry.setValue(name="comment", value=args.ecl_comment)
    
        logfile = ('log_mcc_submit_{}.txt'.format(now))
        with open(logfile, 'w') as lfile:
            lfile.write(log_stream.getvalue())
    
        ecl_entry.addAttachment(name=logfile, filename="{}/{}".format(
            cwd, logfile))
    
        elconn = ECLConnection(url=ECL_URL, username=args.ecl_user,
                password=args.ecl_password)
    
        logging.info("Posting the entry to dunepro ECL now.")
        response = elconn.post(ecl_entry)
        logging.info("Response from ECL: {}".format(response))
        elconn.close()
    
    print(log_stream.getvalue())
