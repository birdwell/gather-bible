/**
 * Whether a host deliberately ended a session.
 *
 * Current apps set `endedAt`. Older apps only clear `state.active`, which a
 * dropped connection also does. A drop also marks the host's participant
 * inactive and an older app's end doesn't, so that tells the two apart. An
 * older host who ended a session and later disconnected still looks like a
 * drop.
 *
 * @param {object} session Session data.
 * @return {boolean} True when the session is over.
 */
function isSessionEnded(session) {
  const state = session?.state;
  if (!state) return false;
  if (state.endedAt) return true;
  if (state.active !== false) return false;
  return session.participants?.[state.hostId]?.active !== false;
}

/**
 * Finds the session for a join code, preferring one that hasn't ended.
 *
 * Ended sessions report NOT_FOUND so older apps show their usual message, and
 * `reason` lets current apps say the session ended.
 *
 * @param {object} sessions Sessions by ID.
 * @param {string} code Uppercased join code.
 * @return {object} The lookup response.
 */
function findSessionByJoinCode(sessions, code) {
  let foundEnded = false;

  for (const [sessionId, session] of Object.entries(sessions)) {
    if (session?.state?.joinCode !== code) continue;
    if (!isSessionEnded(session)) return {sessionId, status: "FOUND"};
    foundEnded = true;
  }

  return foundEnded ?
    {status: "NOT_FOUND", reason: "ENDED"} :
    {status: "NOT_FOUND"};
}

module.exports = {isSessionEnded, findSessionByJoinCode};
