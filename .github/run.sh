#!/bin/sh

cd $(dirname $0)/..

gstart () {
  echo "##[group]$@"
}

gend () {
  echo '##[endgroup]'
}

pgroup () {
  gstart "$@"
    "$@"
  gend
}

gstart 'Set fedora remote'
  git remote rename origin github
  git remote add origin https://src.fedoraproject.org/rpms/ghdl.git
  git fetch origin
  git checkout -b tmp
  git branch -u origin/master
gend

GHDL_COMMIT="$(curl https://api.github.com/repos/ghdl/ghdl/commits/master | grep -oP '^  "sha": "\K[0-9a-z]*')"
sed -i.bak "s/\(%global ghdlcommit\).*/\1 ${GHDL_COMMIT}/g;s/\(%global ghdlgitrev \).*\(git.*\)/\1$(date +%Y%m%d)git\2/g" ghdl.spec

gstart 'Diff'
  git diff ghdl.spec
gend

docker run --rm -v /$(pwd):/wrk -w //wrk ghdl/dist:rpm sh -c "
  pgroup () {
    echo \"##[group]\$@\"
      \"\$@\"
    echo '##[endgroup]'
  }
  pgroup dnf builddep -y ghdl.spec
  pgroup fedpkg sources
  pgroup spectool -g ghdl.spec
  pgroup fedpkg --verbose local
"
