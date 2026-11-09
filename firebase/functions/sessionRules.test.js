const test = require("node:test");
const assert = require("node:assert");
const {isSessionEnded, findSessionByJoinCode} = require("./sessionRules");

const session = (state = {}, hostActive = true) => ({
  state: {joinCode: "ABC123", hostId: "host", active: true, ...state},
  participants: {host: {isHost: true, active: hostActive}},
});

test("a live session isn't ended", () => {
  assert.strictEqual(isSessionEnded(session()), false);
});

test("endedAt means ended", () => {
  assert.strictEqual(isSessionEnded(session({endedAt: 1000})), true);
});

test("a dropped host marks themselves inactive, so it isn't ended", () => {
  assert.strictEqual(isSessionEnded(session({active: false}, false)), false);
});

test("older apps end sessions while the host stays active", () => {
  assert.strictEqual(isSessionEnded(session({active: false}, true)), true);
});

test("inactive with a missing host record counts as ended", () => {
  const orphan = {state: {hostId: "host", active: false}, participants: {}};
  assert.strictEqual(isSessionEnded(orphan), true);
});

test("lookup finds a live session", () => {
  const result = findSessionByJoinCode({s1: session()}, "ABC123");
  assert.deepStrictEqual(result, {sessionId: "s1", status: "FOUND"});
});

test("lookup keeps a dropped host's session joinable", () => {
  const dropped = session({active: false}, false);
  const result = findSessionByJoinCode({s1: dropped}, "ABC123");
  assert.deepStrictEqual(result, {sessionId: "s1", status: "FOUND"});
});

test("lookup rejects an ended session and says why", () => {
  const ended = session({endedAt: 1000});
  const result = findSessionByJoinCode({s1: ended}, "ABC123");
  assert.deepStrictEqual(result, {status: "NOT_FOUND", reason: "ENDED"});
});

test("lookup prefers a live session over an ended one", () => {
  const sessions = {s1: session({endedAt: 1000}), s2: session()};
  const result = findSessionByJoinCode(sessions, "ABC123");
  assert.deepStrictEqual(result, {sessionId: "s2", status: "FOUND"});
});

test("lookup reports an unknown code", () => {
  const result = findSessionByJoinCode({s1: session()}, "ZZZ999");
  assert.deepStrictEqual(result, {status: "NOT_FOUND"});
});
