#!/usr/bin/env bash
set -euo pipefail

# Sprint 2 Product Owner demonstration. All inference uses real meeting audio.
# --check validates prerequisites; --rehearsal runs the CLI without claiming
# that a human listened to audio or verified a speaker identity.

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$root"
mode="${1:-live}"
if [[ "$mode" != live && "$mode" != --check && "$mode" != --rehearsal ]]; then
  printf 'Usage: %s [--check|--rehearsal]\n' "$0" >&2
  exit 2
fi

ami="/private/tmp/meeting-minutes-ami/ES2002a/ES2002a.Mix-Headset.wav"
ami_short="/private/tmp/meeting-minutes-ami/ES2002a/ES2002a.Headset.120s.wav"
sejm="/private/tmp/meeting-polish-gor-20241016-10min.wav"
models="/private/tmp/meeting-minutes-models"
fluid="$root/experiments/FluidAdapter/.build/release/meeting-fluid-asr"
mlx="$root/experiments/MinutesAdapter/.build/out/Products/Release/meeting-mlx-minutes"
shader="$root/experiments/MinutesAdapter/.build/out/Products/Release/mlx.metallib"
qwen="$root/.models/qwen3-30b-a3b-instruct-2507-4bit"

stage() { printf '\n\n=== %s ===\n' "$1"; }
pause() {
  if [[ "$mode" == live ]]; then
    printf '\nNaciśnij Enter, gdy Product Owner zobaczył wynik tego etapu. '
    read -r _
  fi
}
require_file() {
  if [[ ! -f "$1" ]]; then printf 'Brak pliku: %s\n' "$1" >&2; exit 2; fi
}
require_dir() {
  if [[ ! -d "$1" ]]; then printf 'Brak katalogu: %s\n' "$1" >&2; exit 2; fi
}
for command in swift jq shasum; do
  if ! command -v "$command" >/dev/null; then
    printf 'Brak programu %s w PATH\n' "$command" >&2; exit 2
  fi
done
for path in "$ami" "$ami_short" "$sejm" "$fluid" "$mlx" "$shader" "$qwen/config.json"; do require_file "$path"; done
for path in "$models/parakeet-tdt-0.6b-v2" "$models/parakeet-tdt-0.6b-v3" "$models/offline-diarizer/speaker-diarization" "$qwen"; do require_dir "$path"; done
require_file "$root/progress/sprint_2/tests/multistage_20261004/ami/record.json"
require_file "$root/progress/sprint_2/tests/multistage_20261004/sejm/record.json"
require_file "$root/progress/sprint_2/tests/5DC83D71-D1B0-4568-A66D-70F3B9A71D46.json"

stage '0. Cel i architektura'
printf '%s\n' 'Cel: sprawdzić lokalny przepływ nagranie → transkrypcja → rozpoznanie mówców → przegląd operatora → robocze minuty.'
printf '%s\n' 'Parakeet/FluidAudio obsługuje mowę; MLX/Qwen 30B tworzy robocze minuty; walidatory i JSON należą do aplikacji.'
printf 'Angielski AMI: %s\nPolski Sejm: %s\n' "$ami" "$sejm"
printf '%s\n' 'Dane są rzeczywistymi, wieloosobowymi spotkaniami; bez danych referencyjnych w wejściu produktu.'
if [[ "$mode" == --check ]]; then
  printf '\nKontrola wstępna OK. Uruchom %s bez argumentów dla pokazu na żywo.\n' "$0"
  exit 0
fi
pause

store="$(mktemp -d /private/tmp/meeting-sprint2-po-demo.XXXXXX)"
english_settings="$store/english-settings.json"
polish_settings="$store/polish-settings.json"
for language in english polish; do
  if [[ "$language" == english ]]; then version=v2; target="$english_settings"; else version=v3; target="$polish_settings"; fi
  jq -n --arg model "$models/parakeet-tdt-0.6b-$version" --arg version "$version" \
    --arg fluid "$fluid" --arg diarizer "$models/offline-diarizer/speaker-diarization" \
    --arg mlx "$mlx" --arg qwen "$qwen" \
    '{transcriber:"fluid",fluidModelDirectory:$model,fluidModelVersion:$version,fluidExecutable:$fluid,fluidDiarizerModelDirectory:$diarizer,fluidDiarizerExecutable:$fluid,mlxModelDirectory:$qwen,mlxExecutable:$mlx}' > "$target"
done
printf 'Katalog wyników pokazu: %s\n' "$store"
cli() {
  if swift run meeting-summarizer "$@" 2>"$store/last-cli-stderr.log"; then
    cat "$store/last-cli-stderr.log" >> "$store/cli-stderr.log"
    return 0
  else
    status=$?
    cat "$store/last-cli-stderr.log" >> "$store/cli-stderr.log"
    printf 'Krok CLI zakończył się statusem %s. Istotne błędy:\n' "$status" >&2
    { grep -E 'Adapter failed:|error:' "$store/last-cli-stderr.log" || true; } | tail -n 8 >&2
    return "$status"
  fi
}

stage '1. Transkrypcja angielska i polska'
english_id="$(cli transcribe "$ami" --transcriber fluid --language en --settings "$english_settings" --store "$store")"
polish_id="$(cli transcribe "$sejm" --transcriber fluid --language pl --settings "$polish_settings" --store "$store")"
printf 'AMI: %s\nSejm: %s\n' "$english_id" "$polish_id"
jq -r '"AMI: \(.segments|length) segmentów; \(.modelRevision); język \(.processingParameters.requestedLanguage)", (.segments[:12] | map(.text) | join(" "))' "$store/$english_id.json"
jq -r '"Sejm: \(.segments|length) segmentów; \(.modelRevision); język \(.processingParameters.requestedLanguage)", (.segments[:40] | map(.text) | join(" "))' "$store/$polish_id.json"
printf '%s\n' 'Sejm, otwarcie posiedzenia około 181–220 s (slajd 6):'
jq -r '[.segments[] | select(.range.startSeconds >= 181 and .range.startSeconds <= 220) | .text] | join(" ")' "$store/$polish_id.json"
printf '%s\n' 'Liczba segmentów i tekst są wynikiem tego uruchomienia. Nie są miarą dokładności.'
pause

stage '2. Słabe audio i anonimowi mówcy'
cli recognize "$english_id" --diarizer fluid --settings "$english_settings" --store "$store" >/dev/null
cli recognize "$polish_id" --diarizer fluid --settings "$polish_settings" --store "$store" >/dev/null
jq -r '"AMI: \([.segments[].speakerID // empty]|unique|join(", ")) | ostrzeżenia: \(.qualityWarnings|length)", (.qualityWarnings[:3][]? | "  \(.range.startSeconds)-\(.range.endSeconds)s \(.speakerID // "brak"): \(.reason)")' "$store/$english_id.json"
jq -r '"Sejm: \([.segments[].speakerID // empty]|unique|join(", ")) | ostrzeżenia: \(.qualityWarnings|length)"' "$store/$polish_id.json"
printf '%s\n' 'Historyczny benchmark: AMI ma cztery osoby w referencji, a system utworzył trzy klastry; ostrzeżenie nie identyfikuje osoby.'
pause

stage '3. Czyszczenie transkrypcji i przegląd operatora'
cli inspect-cleanup "$polish_id" --store "$store" > "$store/sejm-cleanup.json"
jq -r '"Propozycje połączeń: \(.candidates|length); wypowiedzi czytelnicze: \(.utterances|length)", (.candidates[] | select(.disposition == "joinPrevious") | "  \(.segmentID): \(.reason) -> \(.proposedSpeakerID // "brak")")' "$store/sejm-cleanup.json"
printf '%s\n' 'Sejm, surowe segmenty w okolicy 565–569 s:'
jq -r '.segments[] | select(.range.startSeconds >= 565 and .range.startSeconds <= 569) | "  \(.id) [\(.range.startSeconds)-\(.range.endSeconds)s] \(.speakerID // "brak"): \(.text)"' "$store/$polish_id.json"
printf '%s\n' 'Proponowana czytelnicza wypowiedź obejmująca ten zakres:'
jq -r '.utterances[] | select(.range.startSeconds <= 567 and .range.endSeconds >= 567) | "  \(.id) \(.speakerID // "brak"): \(.text)"' "$store/sejm-cleanup.json"
printf '%s\n' 'Surowe segmenty i proponowany widok czytelniczy pozostają osobno. Propozycja nie dowodzi tożsamości mówcy.'
guard_segment="$(jq -r 'first(.segments[] | select(.range.startSeconds >= 565 and .range.startSeconds <= 569) | .id)' "$store/$polish_id.json")"
if [[ -z "$guard_segment" || "$guard_segment" == null ]]; then
  printf '%s\n' 'Brak segmentu Sejmu w zakresie pokazu kontroli; przerwij i sprawdź transkrypcję.' >&2
  exit 2
fi
mkdir -p "$store/guard"
cp "$store/$polish_id.json" "$store/guard/$polish_id.json"
before_hash="$(shasum -a 256 "$store/guard/$polish_id.json")"
guard_status=0
cli transcribe correct "$polish_id" "$guard_segment" 'NIE ZAPISUJ' --store "$store/guard" >/dev/null || guard_status=$?
after_hash="$(shasum -a 256 "$store/guard/$polish_id.json")"
if [[ "$guard_status" != 2 || "$before_hash" != "$after_hash" ]]; then
  printf '%s\n' 'BŁĄD: kontrola odmowy korekty bez odsłuchu nie przeszła.' >&2
  exit 2
fi
printf 'Kontrola na kopii realnego rekordu: brak --audio-reviewed yes → status %s; SHA-256 bez zmiany.\n' "$guard_status"
if [[ "$mode" == live ]]; then
  printf '\nOtwórz drugie okno Terminala i uruchom dokładnie:\n'
  printf 'cd %q && swift run meeting-review %q --store %q\n' "$root" "$polish_id" "$store"
  printf '%s\n' 'W aplikacji odsłuchaj około 565–569 s oraz wybrany problematyczny fragment; potem wróć tutaj.'
  printf 'Czy odsłuchano zakres w Meeting Review? [tak/nie] '
  read -r audio_reviewed
  if [[ "$audio_reviewed" == tak ]]; then
    printf 'ID błędnego segmentu do korekty (Enter = brak): '
    read -r segment_id
    if [[ -n "$segment_id" ]]; then
      if ! jq -e --arg id "$segment_id" '.segments[] | select(.id == $id)' "$store/$polish_id.json" >/dev/null; then
        printf 'Segment %s nie istnieje; korekta pominięta.\n' "$segment_id"
      else
        jq -r --arg id "$segment_id" '.segments[] | select(.id == $id) | "Przed: \(.id) [\(.range.startSeconds)-\(.range.endSeconds)s] \(.text)"' "$store/$polish_id.json"
        printf 'Czy odsłuchałeś DOKŁADNIE ten zakres czasu? [tak/nie] '
        read -r exact_range_reviewed
        if [[ "$exact_range_reviewed" == tak ]]; then
          printf 'Tekst potwierdzony odsłuchem (Enter = brak): '
          read -r corrected_text
          if [[ -n "$corrected_text" ]]; then
            cli transcribe correct "$polish_id" "$segment_id" "$corrected_text" --audio-reviewed yes --note 'Product Owner demo: correction after operator playback' --store "$store" >/dev/null
            jq -r --arg id "$segment_id" '"Oryginał ASR: ", (.segments[] | select(.id == $id) | .text), "Historia korekt:", (.transcriptCorrections[] | select(.segmentID == $id) | "  \(.correctedText)")' "$store/$polish_id.json"
          fi
        else
          printf '%s\n' 'Korekta pominięta: wskazany segment nie został potwierdzony odsłuchem.'
        fi
      fi
    fi
  else
    printf '%s\n' 'Bez odsłuchu nie zapisujemy korekty ani potwierdzenia jakości dźwięku.'
  fi
else
  printf '%s\n' 'Tryb próby automatycznej: bez odsłuchu, korekty i twierdzenia o sprawdzeniu audio.'
fi
pause

stage '4. Przypisanie nazw'
printf '%s\n' 'Identyfikacja po głosie nie została potwierdzona; obecne etykiety pozostają neutralne.'
if [[ "$mode" == live ]]; then
  printf 'Czy sprawdzono odsłuchem CAŁY klaster mówcy, którego nazwę chcesz przypisać? [tak/nie] '
  read -r cluster_verified
  if [[ "$cluster_verified" == tak ]]; then
    printf 'Spotkanie [ami/sejm]: '
    read -r which_meeting
    if [[ "$which_meeting" == ami ]]; then chosen_id="$english_id"; elif [[ "$which_meeting" == sejm ]]; then chosen_id="$polish_id"; else chosen_id=""; fi
    if [[ -n "$chosen_id" ]]; then
      printf 'ID klastra (np. S1): '
      read -r speaker_id
      if jq -e --arg id "$speaker_id" '[.segments[].speakerID] | index($id) != null' "$store/$chosen_id.json" >/dev/null; then
        printf 'Zweryfikowane imię i nazwisko: '
        read -r speaker_name
        if [[ -n "$speaker_name" ]]; then
          printf '\nKomenda zapisu nazwiska dla bieżącego rekordu:\n'
          printf 'swift run meeting-summarizer recognize name %q %q %q --store %q\n' "$chosen_id" "$speaker_id" "$speaker_name" "$store"
          cli recognize name "$chosen_id" "$speaker_id" "$speaker_name" --store "$store" >/dev/null
          jq -r '.speakerNames | to_entries[] | "\(.key) = \(.value)"' "$store/$chosen_id.json"
          printf 'Nazwa dotyczy wszystkich wypowiedzi klastra %s.\n' "$speaker_id"
          printf 'Zamknij otwarte okno Meeting Review i otwórz rekord ponownie:\n'
          printf 'cd %q && swift run meeting-review %q --store %q\n' "$root" "$chosen_id" "$store"
        fi
      else
        printf 'Klaster %s nie istnieje; nazwa pominięta.\n' "$speaker_id"
      fi
    fi
  fi
fi
pause

stage '5. Robocze minuty — aktualny wieloetapowy model 30B'
short_id="$(cli transcribe "$ami_short" --transcriber fluid --language en --settings "$english_settings" --store "$store")"
cli recognize "$short_id" --diarizer fluid --settings "$english_settings" --store "$store" >/dev/null
minutes_status=0
cli summarize "$short_id" --summarizer mlx --pipeline multi-stage --settings "$english_settings" --store "$store" || minutes_status=$?
printf 'AMI 120 s: status generowania=%s\n' "$minutes_status"
jq -r '"Surowe segmenty: \(.segments|length); elementy roboczych minut: \(.reviewItems|length)", (.reviewItems[]? | "  \(.kind) [\(.topicID // "bez wątku")]: \(.text) | cytowane segmenty: \(.sourceSegmentIDs|length)")' "$store/$short_id.json"
if [[ "$minutes_status" != 0 ]]; then printf '%s\n' 'Walidator odrzucił odpowiedź; transkrypcja pozostała. To wynik pokazu, nie poprawne minuty.'; fi
polish_minutes_status=0
cli summarize "$polish_id" --summarizer mlx --pipeline multi-stage --settings "$polish_settings" --store "$store" || polish_minutes_status=$?
printf 'Sejm 10 min: status generowania=%s\n' "$polish_minutes_status"
jq -r '"Surowe segmenty: \(.segments|length); elementy roboczych minut: \(.reviewItems|length)", (.reviewItems[]? | "  \(.kind) [\(.topicID // "bez wątku")]: \(.text) | cytowane segmenty: \(.sourceSegmentIDs|length)")' "$store/$polish_id.json"
if [[ "$polish_minutes_status" != 0 ]]; then printf '%s\n' 'Walidator odrzucił odpowiedź; transkrypcja pozostała. To wynik pokazu, nie poprawne minuty.'; fi
printf '\n%s\n' 'Porównanie: poniższe robocze minuty pochodzą z zapisanego, kontrolowanego uruchomienia tego samego wieloetapowego modelu 30B. Nie są wynikiem bieżącego uruchomienia.'
for meeting in ami sejm; do
  record="$root/progress/sprint_2/tests/multistage_20261004/$meeting/record.json"
  printf '%s — zapisany wynik:\n' "$meeting"
  jq -r '.reviewItems[] | "  \(.kind) [\(.topicID // "bez wątku")]: \(.text) | źródła: \(.sourceSegmentIDs|length)"' "$record"
done
printf '%s\n' 'Przykład błędu znaczenia, nie etykiety mówcy — AMI t5 versus cytowane słowa:'
jq -r '.cleanedTranscript.utterances[] | select(.id == "utt_10" or .id == "utt_13" or .id == "utt_21") | "  \(.id): \(.text)"' "$root/progress/sprint_2/tests/multistage_20261004/ami/record.json"
printf '%s\n' 'Sejm, źródłowe słowa kandydackiej decyzji około 540–546 s:'
jq -r '[.segments[] | select(.range.startSeconds >= 538 and .range.startSeconds <= 548) | .text] | join(" ")' "$root/progress/sprint_2/tests/multistage_20261004/sejm/record.json"
printf '%s\n' 'Historyczny draft sprzed aktualnej bramki jakości (slajd 11; NIE jest wynikiem bieżącego modelu):'
jq -r '.reviewItems[] | "  \(.kind): \(.text) | cytowane segmenty: \(.sourceSegmentIDs|length)"' "$root/progress/sprint_2/tests/5DC83D71-D1B0-4568-A66D-70F3B9A71D46.json"
printf '%s\n' 'Audyt cytowań w zapisanej próbie: AMI 2/5, Sejm 2/4 podsumowań w pełni popartych własnymi źródłami; kandydat decyzji Sejmu 1/2 jawnych sygnałów.'
pause

stage '6. Jakość, porównanie i decyzja'
printf '%s\n' 'Dłuższy test angielski (zapisana próba DOE, 30 minut):'
jq -r '"  \(.timedSegments) segmentów, \(.speakerIds|length) anonimowych identyfikatorów; próby minut: \(.minutesAttempts|length)"' "$root/progress/sprint_2/tests/doe_itiac_day2_run_20261002.json"
printf '%s\n' 'Zmierzony benchmark AMI: Parakeet v2 WER 19,48%; Whisper base.en WER 28,79% (szczegóły i metodologia w ami_asr_benchmark.md).'
printf '%s\n' 'Osobne czytane próbki językowe: Parakeet v3 EN 11,49% / PL 3,41%; Whisper base CPU EN 18,39% / PL 27,27%. To nie jest WER polskiego spotkania.'
printf '%s\n' 'Zmierzony audyt poprzedniego, kontrolowanego uruchomienia 30B: AMI 2/5 i Sejm 2/4 podsumowań w pełni podpartych własnymi cytowaniami.'
printf '%s\n' 'Te liczby pochodzą z zapisanych pomiarów, nie z niniejszego uruchomienia.'
printf '%s\n' 'Wniosek: prototyp pokazuje architekturę i wykrywa część błędów; wygenerowane minuty wymagają kontroli człowieka i nie są gotowe do publikacji.'
printf 'Wyniki tego pokazu: %s\n' "$store"
printf 'AMI=%s Sejm=%s AMI_120s=%s\n' "$english_id" "$polish_id" "$short_id" | tee "$store/record-ids.txt"
