#!/bin/bash

if [ "$WORKLOAD" == "master" ];
then

  if [ ! -f "/opt/hadoop/data/dfs/name/current/VERSION" ]; then
    $HADOOP_HOME/bin/hdfs namenode -format
  fi

  $HADOOP_HOME/bin/hdfs --daemon start namenode
  $HADOOP_HOME/bin/yarn --daemon start resourcemanager


elif [ "$WORKLOAD" == "worker" ];
then

  $HADOOP_HOME/bin/hdfs --daemon start datanode
  $HADOOP_HOME/bin/yarn --daemon start nodemanager

else
    echo "Undefined Workload Type $WORKLOAD, must specify: master, worker"
fi