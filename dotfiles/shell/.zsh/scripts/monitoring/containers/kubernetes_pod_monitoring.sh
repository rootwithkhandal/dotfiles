#!/bin/bash
kubectl get pods --all-namespaces | grep -v 'Running'