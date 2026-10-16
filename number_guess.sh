#!/bin/bash

set -euo pipefail

PSQL="psql --username=freecodecamp --dbname=number_guess -q -t --no-align -c"
USERNAME="number_test_runner_123"

cleanup() {
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
  if [[ -n $USER_ID ]]; then
    $PSQL "DELETE FROM games WHERE user_id = $USER_ID"
    $PSQL "DELETE FROM users WHERE user_id = $USER_ID"
  fi
}

run_game() {
  {
    printf '%s\n' "$USERNAME" "not-an-integer" 0 1001
    seq 1 1000
  } | ./number_guess.sh
}

trap cleanup EXIT
cleanup

FIRST_OUTPUT=$(run_game)
[[ $FIRST_OUTPUT == *"Welcome, $USERNAME! It looks like this is your first time here."* ]]
[[ $FIRST_OUTPUT == *"That is not an integer, guess again:"* ]]
[[ $FIRST_OUTPUT == *"It's higher than that, guess again:"* ]]
[[ $FIRST_OUTPUT == *"It's lower than that, guess again:"* ]]
grep -Eq '^You guessed it in [0-9]+ tries\. The secret number was [0-9]+\. Nice job!$' <<< "$FIRST_OUTPUT"

SECOND_OUTPUT=$(run_game)
grep -Eq "^Welcome back, $USERNAME! You have played 1 games, and your best game took [0-9]+ guesses\.$" <<< "$SECOND_OUTPUT"
grep -Eq '^You guessed it in [0-9]+ tries\. The secret number was [0-9]+\. Nice job!$' <<< "$SECOND_OUTPUT"
[[ $($PSQL "SELECT COUNT(*) FROM games WHERE user_id = (SELECT user_id FROM users WHERE username = '$USERNAME')") == 2 ]]
