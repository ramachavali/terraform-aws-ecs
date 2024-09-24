#!/bin/bash

for i in $(aws ecs list-tasks --cluster ${cluster} --region ${region} --output text |cut -d "/" -f 3) ; do
	aws ecs stop-task --region ${region} --cluster ${cluster} --task ${i} ;
done
