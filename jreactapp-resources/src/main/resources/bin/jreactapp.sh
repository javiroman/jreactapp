#!/bin/sh
# Script structure inspired from Apache Karaf and other Apache projects with similar
# startup approaches
TARGET_FILE=$0

cd $(dirname $TARGET_FILE)
TARGET_FILE=$(basename $TARGET_FILE)

# Iterate down a (possible) chain of symlinks
while [ -L "$TARGET_FILE" ]
do
    TARGET_FILE=$(readlink $TARGET_FILE)
    cd $(dirname $TARGET_FILE)
    TARGET_FILE=$(basename $TARGET_FILE)
done

# Compute the canonicalized name by finding the physical path
# for the directory we're in and appending the target file.
PHYS_DIR=$(pwd -P)

SCRIPT_DIR=$PHYS_DIR
PROGNAME=$(basename "$0")

. "${SCRIPT_DIR}/jreactapp-env.sh"



warn() {
    echo "${PROGNAME}: $*"
}

die() {
    warn "$*"
    exit 1
}

detectOS() {
    # OS specific support (must be 'true' or 'false').
    cygwin=false;
    aix=false;
    os400=false;
    darwin=false;
    case "$(uname)" in
        CYGWIN*)
            cygwin=true
            ;;
        AIX*)
            aix=true
            ;;
        OS400*)
            os400=true
            ;;
        Darwin)
            darwin=true
            ;;
    esac
    # For AIX, set an environment variable
    if ${aix}; then
         export LDR_CNTRL=MAXDATA=0xB0000000@DSA
         echo ${LDR_CNTRL}
    fi
    # In addition to those, go around the linux space and query the widely
    # adopted /etc/os-release to detect linux variants
    if [ -f /etc/os-release ]; then
        . /etc/os-release
    fi
}

unlimitFD() {
    # Use the maximum available, or set MAX_FD != -1 to use that
    if [ "x${MAX_FD}" = "x" ]; then
        MAX_FD="maximum"
    fi

    # Increase the maximum file descriptors if we can
    if [ "${os400}" = "false" ] && [ "${cygwin}" = "false" ]; then
        MAX_FD_LIMIT=$(ulimit -H -n)
        if [ "${MAX_FD_LIMIT}" != 'unlimited' ]; then
            if [ $? -eq 0 ]; then
                if [ "${MAX_FD}" = "maximum" -o "${MAX_FD}" = "max" ]; then
                    # use the system max
                    MAX_FD="${MAX_FD_LIMIT}"
                fi

                ulimit -n ${MAX_FD} > /dev/null
                # echo "ulimit -n" `ulimit -n`
                if [ $? -ne 0 ]; then
                    warn "Could not set maximum file descriptor limit: ${MAX_FD}"
                fi
            else
                warn "Could not query system maximum file descriptor limit: ${MAX_FD_LIMIT}"
            fi
        fi
    fi
}



locateJava() {
    # Setup the Java Virtual Machine
    if $cygwin ; then
        [ -n "${JAVA}" ] && JAVA=$(cygpath --unix "${JAVA}")
        [ -n "${JAVA_HOME}" ] && JAVA_HOME=$(cygpath --unix "${JAVA_HOME}")
    fi

    if [ "x${JAVA}" = "x" ] && [ -r /etc/gentoo-release ] ; then
        JAVA_HOME=$(java-config --jre-home)
    fi
    if [ "x${JAVA}" = "x" ]; then
        if [ "x${JAVA_HOME}" != "x" ]; then
            if [ ! -d "${JAVA_HOME}" ]; then
                die "JAVA_HOME is not valid: ${JAVA_HOME}"
            fi
            JAVA="${JAVA_HOME}/bin/java"
        else
            warn "JAVA_HOME not set; results may vary"
            JAVA=$(type java)
            JAVA=$(expr "${JAVA}" : '.* \(/.*\)$')
            if [ "x${JAVA}" = "x" ]; then
                die "java command not found"
            fi
        fi
    fi
    # if command is env, attempt to add more to the classpath
    if [ "$1" = "env" ]; then
        [ "x${TOOLS_JAR}" =  "x" ] && [ -n "${JAVA_HOME}" ] && TOOLS_JAR=$(find -H "${JAVA_HOME}" -name "tools.jar")
        [ "x${TOOLS_JAR}" =  "x" ] && [ -n "${JAVA_HOME}" ] && TOOLS_JAR=$(find -H "${JAVA_HOME}" -name "classes.jar")
        if [ "x${TOOLS_JAR}" =  "x" ]; then
             warn "Could not locate tools.jar or classes.jar. Please set manually to avail all command features."
        fi
    fi

}

init() {
    # Determine if there is special OS handling we must perform
    detectOS

    # Unlimit the number of file descriptors if possible
    unlimitFD

    # Locate the Java VM to execute
    locateJava "$1"
}


run() {
    BOOTSTRAP_CONF_DIR="${JREACTAPP_HOME}/conf"
    BOOTSTRAP_CONF="${BOOTSTRAP_CONF_DIR}/bootstrap.conf";
    BOOTSTRAP_LIBS="${JREACTAPP_HOME}/lib/*"

    run_as_user=$(grep '^\s*run.as' "${BOOTSTRAP_CONF}" | cut -d'=' -f2)
    # If the run as user is the same as that starting the process, ignore this configuration
    if [ "${run_as_user}" = "$(whoami)" ]; then
        unset run_as_user
    fi

    if $cygwin; then
        if [ -n "${run_as_user}" ]; then
            echo "The run.as option is not supported in a Cygwin environment. Exiting."
            exit 1
        fi;

        JREACTAPP_HOME=$(cygpath --path --windows "${jreactapp_HOME}")
        JREACTAPP_LOG_DIR=$(cygpath --path --windows "${jreactapp_LOG_DIR}")
        JREACTAPP_PID_DIR=$(cygpath --path --windows "${jreactapp_PID_DIR}")
        BOOTSTRAP_CONF=$(cygpath --path --windows "${BOOTSTRAP_CONF}")
        BOOTSTRAP_CONF_DIR=$(cygpath --path --windows "${BOOTSTRAP_CONF_DIR}")
        BOOTSTRAP_LIBS=$(cygpath --path --windows "${BOOTSTRAP_LIBS}")
        BOOTSTRAP_CLASSPATH="${BOOTSTRAP_CONF_DIR};${BOOTSTRAP_LIBS}"
        if [ -n "${TOOLS_JAR}" ]; then
            TOOLS_JAR=$(cygpath --path --windows "${TOOLS_JAR}")
            BOOTSTRAP_CLASSPATH="${TOOLS_JAR};${BOOTSTRAP_CLASSPATH}"
        fi
    else
        if [ -n "${run_as_user}" ]; then
            if ! id -u "${run_as_user}" >/dev/null 2>&1; then
                echo "The specified run.as user ${run_as_user} does not exist. Exiting."
                exit 1
            fi
        fi;
        BOOTSTRAP_CLASSPATH="${BOOTSTRAP_CONF_DIR}:${BOOTSTRAP_LIBS}"
        if [ -n "${TOOLS_JAR}" ]; then
            BOOTSTRAP_CLASSPATH="${TOOLS_JAR}:${BOOTSTRAP_CLASSPATH}"
        fi
    fi

    echo
    echo "Java home: ${JAVA_HOME}"
    echo "Jreactapp home: ${JREACTAPP_HOME}"
    echo
    echo "Bootstrap Config File: ${BOOTSTRAP_CONF}"
    echo

    # run 'start' in the background because the process will continue to run, monitoring NiFi.
    # all other commands will terminate quickly so want to just wait for them

    #setup directory parameters
    BOOTSTRAP_LOG_PARAMS="-Dorg.jreactapp.bootstrap.config.log.dir='${jreactapp_LOG_DIR}'"
    BOOTSTRAP_PID_PARAMS="-Dorg.jreactapp.bootstrap.config.pid.dir='${jreactapp_PID_DIR}'"
    BOOTSTRAP_CONF_PARAMS="-Dorg.jreactapp.bootstrap.config.file='${BOOTSTRAP_CONF}'"

    # uncomment to allow debugging of the bootstrap process
    #BOOTSTRAP_DEBUG_PARAMS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000"

    BOOTSTRAP_DIR_PARAMS="${BOOTSTRAP_LOG_PARAMS} ${BOOTSTRAP_PID_PARAMS} ${BOOTSTRAP_CONF_PARAMS}"

    run_jreactapp_cmd="'${JAVA}' -cp '${BOOTSTRAP_CLASSPATH}' -Xms12m -Xmx24m ${BOOTSTRAP_DIR_PARAMS} ${BOOTSTRAP_DEBUG_PARAMS} ${BOOTSTRAP_JAVA_OPTS} org.jreactapp.bootstrap.RunJreactApp $@"

    if [ -n "${run_as_user}" ]; then
      # Provide SCRIPT_DIR and execute jreactapp-env for the run.as user command
      run_jreactapp_cmd="sudo -u ${run_as_user} sh -c \"SCRIPT_DIR='${SCRIPT_DIR}' && . '${SCRIPT_DIR}/jreactapp-env.sh' && ${run_jreactapp_cmd}\""
    fi

    if [ "$1" = "run" ]; then
      # Use exec to handover PID to RunNiFi java process, instead of foking it as a child process
      run_jreactapp_cmd="exec ${run_jreactapp_cmd}"
    fi

    if [ "$1" = "start" ]; then
        ( eval "cd ${JREACTAPP_HOME} && ${run_jreactapp_cmd}" & )> /dev/null 1>&-
    else
        eval "cd ${JREACTAPP_HOME} && ${run_jreactapp_cmd}"
    fi
    EXIT_STATUS=$?

    # Wait just a bit (3 secs) to wait for the logging to finish and then echo a new-line.
    # We do this to avoid having logs spewed on the console after running the command and then not giving
    # control back to the user
    sleep 3
    echo
}

main() {
    init "$1"
    run "$@"
}


case "$1" in
    install)
        install "$@"
        ;;
    start|stop|run|status|dump|diagnostics|env)
        main "$@"
        ;;
    restart)
        init
        run "stop"
        run "start"
        ;;
    *)
        echo "Usage jreactapp {start|stop|run|restart|status|dump|diagnostics|install}"
        ;;
esac
