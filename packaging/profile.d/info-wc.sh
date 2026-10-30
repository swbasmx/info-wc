if [[ $- == *i* && -z ${INFO_WC_SKIP:-} && -x /usr/bin/info-wc ]]; then
  /usr/bin/info-wc
fi
