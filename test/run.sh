#!/bin/bash
STARTTIME=$(date +%s)

# Sourcing common will source hack/lib/init.sh
source "$(dirname "${BASH_SOURCE}")/../hack/lib/init.sh"

os::util::environment::setup_time_vars

function cleanup()
{
    out=$?
    set +e

    pkill -P $$
    kill_all_processes

    os::test::junit::reconcile_output

    ENDTIME=$(date +%s); echo "$0 took $(($ENDTIME - $STARTTIME)) seconds"
    os::log::info "Exiting with ${out}"
    exit $out
}

trap "exit" INT TERM
trap "cleanup" EXIT

function find_tests() {
    local test_regex="${2}"
    local full_test_list=()
    local selected_tests=()

    full_test_list=($(find "${1}" -maxdepth 1 -name '*.sh'))
    if [ "${#full_test_list[@]}" -eq 0 ]; then
        return 0
    fi
    for test in "${full_test_list[@]}"; do
	test_rel_path=${test#${test::1}*openshift-spark/test/cmd}
        if grep -q -E "${test_regex}" <<< "${test_rel_path}"; then
            selected_tests+=( "${test}" )
        fi
    done

    if [ "${#selected_tests[@]}" -eq 0 ]; then
        os::log::info "No tests were selected by regex in "${1}
        return 1
    else
        echo "${selected_tests[@]}"
    fi
}

orig_project=$(oc project -q)
failed_list=""
failed=false

dirs=($(find "${OS_ROOT}/test/" -mindepth 1 -type d -not -path "./resources*"))
for dir in "${dirs[@]}"; do

    failed_dir=false

    # Get the list of test files in the current directory
    set +e
    output=$(find_tests $dir ${1:-.*})
    res=$?
    set -e
    if [ "$res" -ne 0 ]; then
        echo $output
        continue
    fi

    # Turn the list of tests into an array and check the length, skip if zero
    tests=($(echo "$output"))
    if [ "${#tests[@]}" -eq 0 ]; then
        continue
    fi

    # Create the project here
    name=$(basename ${dir} .sh)
    set +e # For some reason the result here from head is not 0 even though we get the desired result
    namespace=${name}-$(date -Ins | md5sum | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
    set -e
    oc new-project $namespace &> /dev/null
    oc create sa oshinko &> /dev/null
    oc policy add-role-to-user admin system:serviceaccount:$namespace:oshinko &> /dev/null
    echo "++++++ ${dir}"
    echo Using project $namespace

    for test in "${tests[@]}"; do
        echo
        echo "++++ ${test}"
        if ! ${test}; then
            echo "failed: ${test}"
            failed=true
            failed_dir=true
            failed_list=$failed_list'\n\t'$test
        fi
    done
    if [ "$failed_dir" == true -a ${S2I_SAVE_FAIL:-false} == true ]; then
        echo Leaving project $namespace because of failures
    else
        oc delete project $namespace
    fi
done

oc project $orig_project
if [ "$failed" == true ]; then
    echo "One or more tests failed:"
    echo -e $failed_list'\n'
    exit 1
fi
