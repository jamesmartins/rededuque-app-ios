#!/bin/bash
# Fixes ITMS-90035 caused by Unicode NFC/NFD mismatch in the Distribution
# certificate Common Name (e.g. Ç in "PARTICIPAÇÕES").
#
# Xcode embeds a designated requirement using NFD; the cert CN uses NFC, so
# App Store Connect rejects the IPA even though it looks correctly signed.
#
# This script re-signs with requirements based on Team ID (OU) instead of CN.
#
# Prerequisites:
#   - Apple Distribution certificate + private key installed in Keychain
#     (developer.apple.com → Certificates → Apple Distribution → CSR from Keychain)
#   - An App Store IPA exported from Xcode Organizer (Distribute → Export)
#
# Usage:
#   ./scripts/fix-ipa-codesign-requirements.sh "/path/to/Rede Duque.ipa"
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <AppStore.ipa> [output.ipa]" >&2
  exit 1
fi

IPA_IN="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
IPA_OUT="${2:-${IPA_IN%.ipa}-fixed.ipa}"
TEAM_ID="${TEAM_ID:-WBAYHN46PY}"

IDENTITY="$(security find-identity -v -p codesigning | sed -n 's/.*"\(Apple Distribution:.*\)"/\1/p' | head -1 || true)"
if [[ -z "${IDENTITY}" ]]; then
  echo "error: no Apple Distribution identity in Keychain." >&2
  echo "Create one at https://developer.apple.com/account/resources/certificates/list" >&2
  echo "(Apple Distribution, CSR from Keychain Access) and install the .cer." >&2
  exit 1
fi

echo "Using identity: ${IDENTITY}"
echo "Team ID: ${TEAM_ID}"

WORKDIR="$(mktemp -d /tmp/fix-ipa.XXXXXX)"
cleanup() { rm -rf "${WORKDIR}"; }
trap cleanup EXIT

ditto -x -k "${IPA_IN}" "${WORKDIR}/extract"
APP="$(find "${WORKDIR}/extract/Payload" -maxdepth 1 -name '*.app' -print -quit)"
if [[ -z "${APP}" || ! -d "${APP}" ]]; then
  echo "error: no .app found inside IPA" >&2
  exit 1
fi

ENT_DIR="${WORKDIR}/ents"
mkdir -p "${ENT_DIR}"

bundle_id() {
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$1/Info.plist" 2>/dev/null \
    || codesign -d --verbose=2 "$1" 2>&1 | sed -n 's/^Identifier=//p' | head -1
}

sign_item() {
  local path="$1"
  local identifier="$2"
  local ent_file="${ENT_DIR}/$(echo "${path}" | shasum -a 1 | awk '{print $1}').plist"

  codesign -d --entitlements ":${ent_file}" "${path}" 2>/dev/null || true

  local req
  req="=designated => anchor apple generic and identifier \"${identifier}\" and certificate leaf[subject.OU] = \"${TEAM_ID}\" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */"

  local args=(-f -s "${IDENTITY}" --timestamp --options runtime --requirements "${req}" --generate-entitlement-der)
  if [[ -f "${ent_file}" && -s "${ent_file}" ]]; then
    args+=(--entitlements "${ent_file}")
  fi

  echo "  signing ${path#"${WORKDIR}/extract/"} (${identifier})"
  codesign "${args[@]}" "${path}"
}

echo "Signing frameworks..."
if [[ -d "${APP}/Frameworks" ]]; then
  # Sign nested deepest first
  while IFS= read -r -d '' item; do
    if [[ "${item}" == *.framework ]]; then
      ident="$(bundle_id "${item}")"
      sign_item "${item}" "${ident}"
    elif [[ "${item}" == *.dylib ]]; then
      ident="$(codesign -d --verbose=2 "${item}" 2>&1 | sed -n 's/^Identifier=//p' | head -1)"
      sign_item "${item}" "${ident}"
    fi
  done < <(find "${APP}/Frameworks" \( -name '*.framework' -o -name '*.dylib' \) -print0 | sort -z)
fi

echo "Signing plugins..."
if [[ -d "${APP}/PlugIns" ]]; then
  while IFS= read -r -d '' appex; do
    if [[ -d "${appex}/Frameworks" ]]; then
      while IFS= read -r -d '' fw; do
        sign_item "${fw}" "$(bundle_id "${fw}")"
      done < <(find "${appex}/Frameworks" -name '*.framework' -print0)
    fi
    sign_item "${appex}" "$(bundle_id "${appex}")"
  done < <(find "${APP}/PlugIns" -maxdepth 1 -name '*.appex' -print0)
fi

echo "Signing app..."
sign_item "${APP}" "$(bundle_id "${APP}")"

echo "Verifying..."
codesign --verify --deep --strict --verbose=2 "${APP}"
codesign -d -r- "${APP}" 2>&1 | head -5

rm -f "${IPA_OUT}"
mkdir -p "${WORKDIR}/ipa"
mv "${WORKDIR}/extract/Payload" "${WORKDIR}/ipa/Payload"
[[ -d "${WORKDIR}/extract/SwiftSupport" ]] && mv "${WORKDIR}/extract/SwiftSupport" "${WORKDIR}/ipa/SwiftSupport"
[[ -d "${WORKDIR}/extract/Symbols" ]] && mv "${WORKDIR}/extract/Symbols" "${WORKDIR}/ipa/Symbols"
(
  cd "${WORKDIR}/ipa"
  /usr/bin/zip -qry "${IPA_OUT}" .
)

echo "Wrote ${IPA_OUT}"
echo "Upload this IPA with Transporter (or: xcrun altool --upload-app -f \"${IPA_OUT}\" -t ios -u APPLE_ID -p APP_SPECIFIC_PASSWORD)"
