#!/bin/sh
#
#    Licensed to the Apache Software Foundation (ASF) under one or more
#    contributor license agreements.  See the NOTICE file distributed with
#    this work for additional information regarding copyright ownership.
#    The ASF licenses this file to You under the Apache License, Version 2.0
#    (the "License"); you may not use this file except in compliance with
#    the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

# The java implementation to use.
#export JAVA_HOME=/usr/java/jdk1.8.0/

export JREACTAPP_HOME=$(cd "${SCRIPT_DIR}" && cd .. && pwd)

#The directory for the NiFi pid file
export JREACTAPP_PID_DIR="${JREACTAPP_HOME}/run"

#The directory for NiFi log files
export JREACTAPP_LOG_DIR="${JREACTAPP_HOME}/logs"

# Set to false to force the use of Keytab controller service in processors
# that use Kerberos. If true, these processors will allow configuration of keytab
# and principal directly within the processor. If false, these processors will be
# invalid if attempting to configure these properties. This may be advantageous in
# a multi-tenant environment where management of keytabs should be performed only by
# a user with elevated permissions (i.e., users that have been granted the 'ACCESS_KEYTAB'
# restriction).
export JREACTAPP_ALLOW_EXPLICIT_KEYTAB=true