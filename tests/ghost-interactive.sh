#!/bin/sh
set -eu

test_dir=$(mktemp -d)
trap 'rm -r "$test_dir"' EXIT
mkdir "$test_dir/bin"
cp Sources/HafthiMac/Resources/g "$test_dir/g"
chmod +x "$test_dir/g"

cat > "$test_dir/bin/brew" <<'BREW'
#!/bin/sh
exit 0
BREW
cat > "$test_dir/hafthi" <<'APP'
#!/bin/sh
printf '%s\n' "$@" > "$HAFTHI_TEST_RECORD"
APP
chmod +x "$test_dir/bin/brew" "$test_dir/hafthi"

export HAFTHI_GHOST_DIR="$test_dir/state"
HAFTHI_BIN="$test_dir/hafthi" HAFTHI_TEST_RECORD="$test_dir/arguments" \
    PATH="$test_dir/bin:$PATH" "$test_dir/g" brew upgrade > "$test_dir/message"
attempt=0
while [ ! -f "$test_dir/arguments" ] && [ "$attempt" -lt 30 ]; do
    sleep 0.1
    attempt=$((attempt + 1))
done
[ "$(cat "$test_dir/arguments")" = "$(printf '%s\n' --interactive brew upgrade)" ]
grep -q 'separate Hafþi window' "$test_dir/message"
[ ! -d "$test_dir/state/ghost1" ]

# The originating Hafþi window receives a NUL-separated PTY request.
mkdir "$test_dir/inbox"
(
    attempt=0
    while [ ! -f "$test_dir/inbox/ghost1" ] && [ "$attempt" -lt 30 ]; do
        sleep 0.1
        attempt=$((attempt + 1))
    done
    [ -f "$test_dir/inbox/ghost1" ]
    printf '%s\n' "$$" > "$HAFTHI_GHOST_DIR/ghost1/pid"
) &
inbox_reader=$!
HAFTHI_GHOST_INBOX="$test_dir/inbox" PATH="$test_dir/bin:$PATH" "$test_dir/g" brew upgrade > "$test_dir/drawer-message"
wait "$inbox_reader"
grep -q 'Ctrl+G opens its drawer' "$test_dir/drawer-message"
[ "$(tr '\000' '\n' < "$test_dir/inbox/ghost1")" = "$(printf '%s\n' "$PWD" brew upgrade)" ]
