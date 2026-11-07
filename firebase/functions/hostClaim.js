/**
 * Transaction update for a guest taking over a session as host.
 *
 * A host whose connection dropped leaves `active` false with no `endedAt`, and
 * that's when a guest can take over. A host who ended the session sets
 * `endedAt`, and that session stays closed.
 *
 * @param {object|null} current Session data, or null on the first pass.
 * @param {string} userId The claiming user.
 * @param {string} displayName The claiming user's name.
 * @return {object|null|undefined} New data, null to retry against the server,
 *     or undefined to abort.
 */
function applyHostClaim(current, userId, displayName) {
  // The first pass runs against an empty local cache. Aborting here would fail
  // every claim, so hand it back and the server re-runs with the real data.
  if (current === null) return null;

  if (!current.state || current.state.endedAt) return undefined;
  if (!current.participants?.[userId]) return undefined;
  if (current.state.hostId === userId) return current;

  const oldHostId = current.state.hostId;
  if (current.participants[oldHostId]) {
    current.participants[oldHostId].isHost = false;
  }

  current.state.hostId = userId;
  current.state.active = true;
  current.participants[userId].isHost = true;
  current.participants[userId].displayName = displayName;

  return current;
}

/**
 * Whether a finished transaction left the user as host. A session that no
 * longer exists commits as null, so `committed` alone isn't enough.
 *
 * @param {boolean} committed Whether the transaction committed.
 * @param {object|null} session The session data afterward.
 * @param {string} userId The claiming user.
 * @return {boolean} True when the user is now host.
 */
function didClaimSucceed(committed, session, userId) {
  return committed && session?.state?.hostId === userId;
}

module.exports = {applyHostClaim, didClaimSucceed};
