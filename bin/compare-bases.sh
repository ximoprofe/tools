#!/bin/bash
store=$(mktemp -d)

keep=$1
toss=$2
comment() {
  echo "# $1"
}

comment "Using store $store"
{ 
  cd $keep
  find . -type f > $store/keep
  comment "Made keep list in $store $(wc -l $store/keep)"
}
{
  cd $toss
  find . -type f > $store/toss
  comment "Made toss list in $store $(wc -l $store/toss)"
}

sort --parallel=4 $store/keep $store/toss | uniq -d | while read i
do
  if [[ -e "$keep/$i" && -e "$toss/$i" ]]; then
    keep_size=$(stat -c %s "$keep/$i")
    toss_size=$(stat -c %s "$toss/$i")

    if [[ $keep_size == $toss_size ]]; then
      keep_md5=$(cat "$keep/$i" | md5sum)
      toss_md5=$(cat "$toss/$i" | md5sum)
      if [[ $keep_md5 == $toss_md5 ]]; then
        echo "rm \"$toss/$i\""
        comment "keep $keep/$i"
      else
        comment "$i md5 diff $keep_md5 $toss_md5"
      fi
    else
      comment "$i size diff $keep_size $toss_size"
    fi
  else
    comment "Cannot find $keep/$i or $toss/$i"
  fi
done

