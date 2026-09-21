#!/bin/bash
THRESHOLD=80
df -h | awk '{if($5+0 > '$THRESHOLD') print $0}'