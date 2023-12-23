#!/usr/bin/env bash
# Edit the paste buffer
# Script for PasteTransform.
# Receives pasteboard contents on stdin and outputs new contents on stdout.

set -o errexit  # Exit on error

UTI={$1:-public.utf8-plain-text}

if test -n "${EDITOR}" ; then
  editor="${EDITOR}"
else
  # Default editor is MacVim as installed by Homebrew
  for mvim in \
    /usr/local/bin/mvim \
    /opt/homebrew/bin/mvim \
    /Applications/MacVim.app/Contents/bin/mvim \
    ; do
    if test -x "${mvim}" ; then
      editor="${mvim}"
      break
    fi
  done
fi

if test -z "${editor}" ; then
  echo "Macvim (mvim) not found." 1>&2
  exit 1
fi

# Use --nofork for mvim
if [[ ${editor} == *mvim ]] ; then
  editor="${editor} --nofork"
fi

tmpfile=$(mktemp)".txt"
cat > ${tmpfile}
${editor} ${tmpfile}
cat ${tmpfile}
rm -f ${tmpfile}
exit 0
