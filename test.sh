#!/bin/sh

_ROOT_="${_ROOT_:-`cd $(dirname $0) && pwd`}"
_EMACS_="${EMACS:-emacs}"
_TEST_="${_TEST_:-bone}"
_ENV_VER_=
_ENV_ERT_=
_ENV_PKG_=

echo_env() {
  echo "------------"
  echo "VERSION: $_ENV_VER_"
  echo "ERT: $_ENV_ERT_"
  echo "PKG: $_ENV_PKG_"
  echo "TEST: $1"
  echo "------------"
}

test_bone() {
  echo_env "bone|clean"
  ${_EMACS_} --batch                                            \
             --no-window-system                                 \
             --eval="                                           \
(let ((user-emacs-directory (expand-file-name \"${_ROOT_}/\"))) \
  (load (expand-file-name \"${_ROOT_}/init.el\"))               \
  (clean-compiled-files))                                       \
"

  echo_env "bone|compile"
  ${_EMACS_} --batch                                            \
             --no-window-system                                 \
             --eval="                                           \
(let ((user-emacs-directory (expand-file-name \"${_ROOT_}/\"))) \
  (load (expand-file-name \"${_ROOT_}/init.el\")))              \
"

 echo_env "bone|boot"
  ${_EMACS_} --batch                                            \
             --no-window-system                                 \
             --eval="                                           \
(let ((user-emacs-directory (expand-file-name \"${_ROOT_}/\"))) \
  (load (expand-file-name \"${_ROOT_}/init.el\")))              \
"
}

test_debug() {
  echo_env "debug|clean"
  ${_EMACS_} --batch                                            \
             --no-win                                 \
             --eval="                                           \
(let ((user-emacs-directory (expand-file-name \"${_ROOT_}/\"))) \
  (load (expand-file-name \"${_ROOT_}/init.el\"))               \
  (clean-compiled-files))                                       \
"

  echo_env "debug|capture"
  ${_EMACS_} --debug-init                                       \
             --eval="                                           \
(let ((user-emacs-directory (expand-file-name \"${_ROOT_}/\"))) \
  (setq debug-on-error t)                                       \
  (load (expand-file-name \"${_ROOT_}/init.el\"))               \
  (load (emacs-home* \"init.el\")))                             \
"
}

test_axiom() {
  if [ "ert" != "$_ENV_ERT_" ]; then
    echo "#skipped axiom testing, ert no found"
    return 0
  fi

  echo_env "axiom|clean"
  ${_EMACS_} --batch                                          \
             --no-window-system                               \
             --eval="                                         \
(let ((user-emacs-directory (expand-file-name \"${_ROOT_}/\"))) \
  (load (expand-file-name \"${_ROOT_}/init.el\"))               \
  (clean-compiled-files))                                       \
"
  echo_env "axiom|compile"
  ${_EMACS_} --batch                                          \
             --no-window-system                               \
             --eval="                                         \
(let ((user-emacs-directory (expand-file-name \"${_ROOT_}/\")))  \
  (load (expand-file-name \"${_ROOT_}/init.el\"))               \
  (load (emacs-home* \"test.el\"))                              \
  (ert-run-tests-batch-and-exit))                               \
"

  echo_env "axiom|boot"
  ${_EMACS_} --batch                                          \
             --no-window-system                               \
             --eval="                                         \
(let ((user-emacs-directory (expand-file-name \"${_ROOT_}/\")))  \
  (load (expand-file-name \"${_ROOT_}/init.el\"))               \
  (load (emacs-home* \"test.el\"))                              \
  (ert-run-tests-batch-and-exit))                               \
"
}

test_package() {
  if [ "package" != "$_ENV_PKG_" ]; then
    echo "#skipped package testing, package no support"
    return 0
  fi

  echo "#make ${_ROOT_}/private/self-env-spec.el ..."
  mkdir -p "${_ROOT_}/private"
  cat <<END > "${_ROOT_}/private/self-env-spec.el"
(*self-env-spec*
 :put :package
 (list :remove-unused nil
       :package-check-signature 'allow-unsigned
       :allowed t))
END
 
  echo_env "package|clean"
  ${_EMACS_} --batch                                          \
             --no-window-system                               \
             --eval="                                         \
(let ((user-emacs-directory (expand-file-name \"${_ROOT_}/\"))) \
  (load (expand-file-name \"${_ROOT_}/init.el\"))               \
  (clean-compiled-files))                                       \
"

  echo_env "package|compile"
  ${_EMACS_} --batch                                            \
             --no-window-system                                 \
             --eval="                                           \
(let ((user-emacs-directory (expand-file-name \"${_ROOT_}/\"))) \
  (load (expand-file-name \"${_ROOT_}/init.el\")))              \
"

  echo_env "package|boot"
  ${_EMACS_} --batch                                            \
             --no-window-system                                 \
             --eval="                                           \
(let ((user-emacs-directory (expand-file-name \"${_ROOT_}/\"))) \
  (load (expand-file-name \"${_ROOT_}/init.el\")))              \
"
}

# check env
_ENV_VER_="`$_EMACS_ --batch --eval='(prin1 emacs-version)'`"
_ENV_ERT_="`$_EMACS_ --batch --eval='(prin1 (require (quote ert) nil t))'`"
_ENV_PKG_="`$_EMACS_ --batch --eval='(prin1 (require (quote package) nil t))'`"

# test
case "${_TEST_}" in
  bone)     test_bone     ;;
  axiom)    test_axiom    ;;
  package)  test_package  ;;
  debug)    test_debug    ;;
esac


# eof
