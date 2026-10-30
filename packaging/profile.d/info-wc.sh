if [ -z "${INFO_WC_SKIP:-}" ] && [ -x /usr/bin/info-wc ]; then
  case $- in
    *i*) /usr/bin/info-wc ;;
  esac
fi
