const { onCall } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getDatabase } = require("firebase-admin/database");

initializeApp();
const db = getDatabase();

/**
 * Generate a random 6-character alphanumeric join code
 */
function generateJoinCode() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  return Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join("");
}

/**
 * Generate a unique join code for a new session
 */
exports.generateUniqueJoinCode = onCall({ cors: true }, async () => {
  const sessions = (await db.ref("sessions").once("value")).val() || {};
  
  for (let i = 0; i < 10; i++) {
    const code = generateJoinCode();
    const exists = Object.values(sessions).some(s => s?.state?.joinCode === code);
    if (!exists) {
      return { joinCode: code, success: true };
    }
  }
  
  throw new Error("Unable to generate unique join code. Please try again.");
});

/**
 * Lookup a session by join code
 */
exports.lookupJoinCode = onCall({ cors: true }, async (request) => {
  const { joinCode } = request.data || {};
  
  if (!joinCode || joinCode.length !== 6) {
    throw new Error("Invalid join code");
  }
  
  const code = joinCode.toUpperCase();
  const sessions = (await db.ref("sessions").once("value")).val() || {};
  
  for (const [sessionId, data] of Object.entries(sessions)) {
    if (data?.state?.joinCode === code) {
      return { sessionId, status: "FOUND" };
    }
  }
  
  return { status: "NOT_FOUND" };
});

/**
 * Claim host role in a session (when current host is inactive)
 */
exports.claimHost = onCall({ cors: true }, async (request) => {
  const { sessionId, userId, displayName } = request.data || {};
  
  if (!sessionId || !userId || !displayName) {
    throw new Error("Missing required fields");
  }
  
  const sessionRef = db.ref(`sessions/${sessionId}`);
  
  const result = await sessionRef.transaction((current) => {
    if (!current?.state?.active) return;
    if (!current.participants?.[userId]) return;
    if (current.state.hostId === userId) return current;
    
    // Remove host from old host
    const oldHostId = current.state.hostId;
    if (current.participants[oldHostId]) {
      current.participants[oldHostId].isHost = false;
    }
    
    // Set new host
    current.state.hostId = userId;
    current.participants[userId].isHost = true;
    current.participants[userId].displayName = displayName;
    
    return current;
  });
  
  if (!result.committed) {
    throw new Error("Failed to claim host");
  }
  
  return { success: true };
});