# yazi-learn: short, hands-on Yazi lessons in a throwaway playground.
# Wrapped by writeShellApplication (home/yazi-learn.nix), which adds `set -euo pipefail`,
# puts the tools on PATH, runs shellcheck at build time and sets YAZI_LEARN_DATA: the
# directory with lesson texts generated from Yazi's real keymap (generate.py).

data="$YAZI_LEARN_DATA"
playground="${XDG_DATA_HOME:-$HOME/.local/share}/yazi-learn/playground"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/yazi-learn"
done_file="$state_dir/done"
lesson_count=$(wc -l <"$data/titles.tsv")

usage() {
  cat <<EOF
yazi-learn: learn Yazi with $lesson_count short lessons.

  yazi-learn start       build a fresh playground and open Yazi in it
  yazi-learn lesson [n]  show lesson n (default: the first one not done yet)
  yazi-learn done [n]    mark lesson n (default: the current one) as done
  yazi-learn list        all lessons, with progress
  yazi-learn answer [n]  the answer to a lesson's check question
  yazi-learn quiz [k]    k flashcards (default 10), mostly from lessons you finished
  yazi-learn cheat       every Yazi key (same as Yazi's live help)
  yazi-learn reset       forget progress and delete the playground

Playground: $playground
EOF
}

is_done() { [ -f "$done_file" ] && grep -qx "$1" "$done_file"; }

current_lesson() {
  for n in $(seq 1 "$lesson_count"); do
    if ! is_done "$n"; then
      echo "$n"
      return
    fi
  done
  echo "$lesson_count"
}

check_number() {
  case "$1" in
    '' | *[!0-9]*) echo "yazi-learn: '$1' is not a lesson number" >&2; exit 1 ;;
  esac
  if [ "$1" -lt 1 ] || [ "$1" -gt "$lesson_count" ]; then
    echo "yazi-learn: lessons go from 1 to $lesson_count" >&2
    exit 1
  fi
}

# --- The playground ---------------------------------------------------------------------
build_playground() {
  rm -rf "$playground"
  mkdir -p "$playground"
  cd "$playground"

  # Nesting, for moving around.
  mkdir -p nested/level-1/level-2/level-3
  echo "You found the deepest file." >nested/level-1/level-2/level-3/deep.txt
  echo "level one" >nested/level-1/one.txt

  # Spaces in names (quote them in shell commands!).
  mkdir -p "my documents"
  echo "Agenda: learn yazi" >"my documents/meeting notes.txt"
  echo "two spaces" >"my documents/file  with  two  spaces.md"

  # Hidden files: only shown after toggling hidden files.
  echo "theme = dark" >.hidden-config
  mkdir -p .secret
  echo "not so secret" >.secret/notes.txt

  # A symlink, for "follow".
  ln -s nested/level-1/level-2/level-3 link-to-deep

  # Near-duplicates, for filter/find/search and sorting.
  mkdir -p reports
  for name in report.txt report-final.txt report-final-v2.txt report_final.txt Report.txt report.md; do
    echo "quarterly report ($name)" >"reports/$name"
  done

  # Sizes and dates that differ, for sorting and linemodes.
  mkdir -p sort-me
  head -c 10 /dev/zero >sort-me/small.bin
  head -c 50000 /dev/zero >sort-me/medium.bin
  head -c 2000000 /dev/zero >sort-me/large.bin
  touch -d "2020-01-01" sort-me/small.bin
  touch -d "2023-06-15" sort-me/large.bin

  # Images (preview them!), made with ImageMagick.
  mkdir -p images
  magick -size 320x200 xc:'#bf616a' images/red.png
  magick -size 320x200 xc:'#a3be8c' images/green.png
  magick -size 320x200 gradient:'#5277c3-#7ebae4' images/gradient.png
  magick -size 320x200 plasma:fractal images/plasma.png

  # Files to bulk-rename.
  mkdir -p rename-me
  for i in 1 2 3 4 5; do
    magick -size 64x64 "xc:#28344a" "rename-me/IMG_000$i.png"
  done

  # A file with TODO lines, for searching contents.
  cat >todo.txt <<'TODO'
Shopping list
TODO: buy coffee
- milk
TODO: learn the yazi search keys
Done: install yazi
TODO
  printf '# Notes\n\nSome *markdown* to preview.\n\n- one\n- two\n' >notes.md

  # Archives, to preview and extract.
  mkdir -p archives
  zip -qr archives/images.zip images
  tar -czf archives/reports.tar.gz reports

  # A small git repo with changes, for the git plugin's status signs.
  mkdir -p git-repo
  (
    cd git-repo
    git init -q
    echo "hello" >README.md
    echo "print('hi')" >app.py
    git add . && git -c user.name=learner -c user.email=learner@example.invalid commit -qm "first commit"
    echo "changed" >>README.md
    echo "new file" >untracked.txt
  )

  # Many files, for jumping, filtering and selecting a lot at once.
  mkdir -p many-files
  for i in $(seq -w 1 500); do
    echo "file $i" >"many-files/file-$i.txt"
  done

  # A place to practise creating, deleting and pasting.
  mkdir -p scratch
  echo "Delete me (trash)" >scratch/trash-me.txt
  echo "Delete me (permanently)" >scratch/gone-for-good.txt
}

# --- Commands -----------------------------------------------------------------------------
cmd="${1:-help}"
[ $# -gt 0 ] && shift

case "$cmd" in
  start)
    build_playground
    echo "Playground ready. Lesson $(current_lesson): run 'yazi-learn lesson' in another terminal."
    exec yazi "$playground"
    ;;
  lesson)
    n="${1:-$(current_lesson)}"
    check_number "$n"
    cat "$data/lesson-$(printf %02d "$n").txt"
    echo
    if is_done "$n"; then
      echo "(done) Next: yazi-learn lesson $((n < lesson_count ? n + 1 : n))"
    else
      echo "When you can answer the check question: yazi-learn done $n"
    fi
    ;;
  answer)
    n="${1:-$(current_lesson)}"
    check_number "$n"
    cat "$data/answer-$(printf %02d "$n").txt"
    ;;
  done)
    n="${1:-$(current_lesson)}"
    check_number "$n"
    mkdir -p "$state_dir"
    is_done "$n" || echo "$n" >>"$done_file"
    echo "Lesson $n done."
    if [ "$n" -lt "$lesson_count" ]; then echo "Next: yazi-learn lesson $(current_lesson)"; fi
    ;;
  list)
    while IFS=$'\t' read -r n title; do
      if is_done "$n"; then mark="x"; else mark=" "; fi
      printf '[%s] %2d. %s\n' "$mark" "$n" "$title"
    done <"$data/titles.tsv"
    ;;
  quiz)
    count="${1:-10}"
    # Weighting: cards from finished lessons go in three times, others once; after
    # shuffling, repeats are dropped, so finished lessons simply come up first more often.
    deck=$(mktemp)
    trap 'rm -f "$deck"' EXIT
    while IFS=$'\t' read -r n desc keys; do
      copies=1
      if is_done "$n"; then copies=3; fi
      for _ in $(seq "$copies"); do printf '%s\t%s\n' "$desc" "$keys" >>"$deck"; done
    done <"$data/cards.tsv"
    right=0
    asked=0
    while IFS=$'\t' read -r desc keys; do
      asked=$((asked + 1))
      printf '\n%d/%d  Which key: %s ?  (Enter to reveal) ' "$asked" "$count" "$desc"
      read -r _ </dev/tty
      printf '      %s    Did you know it? [y/N] ' "$keys"
      read -r reply </dev/tty
      case "$reply" in y | Y) right=$((right + 1)) ;; esac
    done < <(shuf "$deck" | awk '!seen[$0]++' | head -n "$count")
    printf '\n%d of %d right.\n' "$right" "$asked"
    ;;
  cheat)
    cat "$data/cheat.txt"
    ;;
  reset)
    rm -rf "$playground" "$state_dir"
    echo "Progress and playground removed."
    ;;
  help | -h | --help)
    usage
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
