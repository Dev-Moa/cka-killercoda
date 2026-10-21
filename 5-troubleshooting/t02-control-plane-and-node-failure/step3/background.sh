#!/bin/bash
# Part C setup, from the exercise ("on the worker node": sudo systemctl
# stop kubelet). The worker on this image is node01.
ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 node01 'sudo systemctl stop kubelet'
exit 0
