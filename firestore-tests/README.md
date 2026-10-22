# Firestore rules tests

Runs `../firestore.rules` against the local emulator (no deploy, no real project).

    npm install
    npm test        # needs Java 11+ and firebase-tools on PATH

Covers: private finance is manager-only, cross-agency isolation, agency docs
private to members, joinKeys get-only, editors join only with the current key,
role/agencyId/rating lock, agency + key creation and key regeneration, DM participants.
