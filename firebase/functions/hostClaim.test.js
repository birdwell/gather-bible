const test = require("node:test");
const assert = require("node:assert");
const {applyHostClaim, didClaimSucceed} = require("./hostClaim");

const session = (state = {}) => ({
  state: {hostId: "host", active: false, ...state},
  participants: {
    host: {displayName: "Josh", isHost: true, active: false},
    guest: {displayName: "Sam", isHost: false, active: true},
  },
});

test("retries on the server when the local cache is empty", () => {
  assert.strictEqual(applyHostClaim(null, "guest", "Sam"), null);
});

test("guest takes over after the host's connection drops", () => {
  const result = applyHostClaim(session(), "guest", "Sam");
  assert.strictEqual(result.state.hostId, "guest");
  assert.strictEqual(result.state.active, true);
  assert.strictEqual(result.participants.guest.isHost, true);
  assert.strictEqual(result.participants.host.isHost, false);
});

test("a deliberately ended session can't be claimed", () => {
  const ended = session({endedAt: 1000});
  assert.strictEqual(applyHostClaim(ended, "guest", "Sam"), undefined);
});

test("someone outside the session can't claim it", () => {
  assert.strictEqual(applyHostClaim(session(), "stranger", "Eve"), undefined);
});

test("a session with no state can't be claimed", () => {
  const empty = {participants: {}};
  assert.strictEqual(applyHostClaim(empty, "guest", "Sam"), undefined);
});

test("the current host claiming again changes nothing", () => {
  const current = session({active: true});
  const result = applyHostClaim(current, "host", "Josh");
  assert.strictEqual(result.state.hostId, "host");
});

test("success requires the claimant to actually be host afterward", () => {
  const claimed = applyHostClaim(session(), "guest", "Sam");
  assert.strictEqual(didClaimSucceed(true, claimed, "guest"), true);
  assert.strictEqual(didClaimSucceed(false, claimed, "guest"), false);
  assert.strictEqual(didClaimSucceed(true, null, "guest"), false);
  assert.strictEqual(didClaimSucceed(true, session(), "guest"), false);
});
