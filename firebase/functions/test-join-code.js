/**
 * Test script for join code functionality
 * This demonstrates how to use the new Cloud Functions
 */

const { getFunctions, httpsCallable } = require('firebase/functions');

// Example usage of lookupJoinCode function
async function testLookupJoinCode(firebaseApp) {
  const functions = getFunctions(firebaseApp);
  const lookupJoinCode = httpsCallable(functions, 'lookupJoinCode');
  
  try {
    // Test with a valid join code
    const result = await lookupJoinCode({ joinCode: 'ABC123' });
    console.log('Lookup result:', result.data);
    
    if (result.data.status === 'FOUND') {
      console.log(`Session found! Session ID: ${result.data.sessionId}`);
    } else {
      console.log('Session not found with that join code');
    }
  } catch (error) {
    console.error('Error looking up join code:', error.message);
  }
}

// Example usage of generateUniqueJoinCode function
async function testGenerateJoinCode(firebaseApp) {
  const functions = getFunctions(firebaseApp);
  const generateUniqueJoinCode = httpsCallable(functions, 'generateUniqueJoinCode');
  
  try {
    const result = await generateUniqueJoinCode();
    console.log('Generated join code:', result.data.joinCode);
    return result.data.joinCode;
  } catch (error) {
    console.error('Error generating join code:', error.message);
    return null;
  }
}

// Example client-side implementation for joining a session
async function joinSessionWithCode(firebaseApp, joinCode, userId, userName) {
  const functions = getFunctions(firebaseApp);
  const lookupJoinCode = httpsCallable(functions, 'lookupJoinCode');
  const joinSession = httpsCallable(functions, 'joinSession');
  
  try {
    // Step 1: Lookup the join code
    const lookupResult = await lookupJoinCode({ joinCode: joinCode.toUpperCase() });
    
    if (lookupResult.data.status === 'NOT_FOUND') {
      throw new Error('Invalid join code. Please check the code and try again.');
    }
    
    const sessionId = lookupResult.data.sessionId;
    console.log(`Found session: ${sessionId}`);
    
    // Step 2: Join the session (you might want to add sessionId parameter to joinSession function)
    await joinSession({ uid: userId, name: userName });
    
    console.log(`Successfully joined session ${sessionId}`);
    return sessionId;
    
  } catch (error) {
    console.error('Error joining session:', error.message);
    throw error;
  }
}

module.exports = {
  testLookupJoinCode,
  testGenerateJoinCode,
  joinSessionWithCode
};