#!/usr/bin/env sh
set -v

# dev_requirements should not be needed for testing; don't install them to make sure
pip install -r test_requirements.txt
pip install -r doc_requirements.txt

export COMMIT_MSG=$(git show HEAD^2 -s)
export PULP_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/pulp\/pulpcore\/pull\/(\d+)' | awk -F'/' '{print $7}')
export PULP_FILE_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/pulp\/pulp_file\/pull\/(\d+)' | awk -F'/' '{print $7}')
export PULP_SMASH_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/PulpQE\/pulp-smash\/pull\/(\d+)' | awk -F'/' '{print $7}')

if [ -z "$PULP_PR_NUMBER" ]; then
  pip install "git+https://github.com/pulp/pulpcore.git#egg=pulpcore"[postgres]
else
  cd ../
  git clone https://github.com/pulp/pulpcore.git
  cd pulpcore
  git fetch origin +refs/pull/$PULP_PR_NUMBER/merge
  git checkout FETCH_HEAD
  pip install -e .[postgres]
  cd ../pulpcore-plugin
fi

pip install -e .

if [ "$TEST" = 'docs' ]; then
  pip3 install 'sphinx<1.8.0' sphinxcontrib-openapi sphinx_rtd_theme
  return "$?"
fi

cd ../
git clone https://github.com/pulp/pulp_file.git
cd pulp_file
if [ -n "$PULP_FILE_PR_NUMBER" ]; then
  git fetch origin +refs/pull/$PULP_FILE_PR_NUMBER/merge
  git checkout FETCH_HEAD
fi
pip install -e .
cd ../pulpcore-plugin


if [ ! -z "$PULP_SMASH_PR_NUMBER" ]; then
  pip uninstall -y pulp-smash
  cd ../
  git clone https://github.com/PulpQE/pulp-smash.git
  cd pulp-smash
  git fetch origin +refs/pull/$PULP_SMASH_PR_NUMBER/merge
  git checkout FETCH_HEAD
  pip install -e .
  cd ../pulpcore-plugin
fi

pip install -e .
