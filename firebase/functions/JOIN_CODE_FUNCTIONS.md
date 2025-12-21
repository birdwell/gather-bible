# Join Code Cloud Functions

This document describes the new Cloud Functions implemented for join code functionality in the Gather Bible app.

## Functions

### `lookupJoinCode`

A callable Cloud Function that allows guests to lookup a session by its join code.

**Function Type:** `onCall`
**Rate Limiting:** 20 requests per minute per IP address

#### Request Parameters
```javascript
{
  joinCode: "ABC123"  // 6-character alphanumeric join code
}
```

#### Response
```javascript
// When session is found
{
  sessionId: "session_123",
  status: "FOUND"
}

// When session is not found
{
  status: "NOT_FOUND"
}
```

#### Error Handling
- `RATE_LIMIT_EXCEEDED`: Too many requests from the same IP address
- `JOIN_CODE_REQUIRED`: No join code provided in request
- `INVALID_JOIN_CODE_FORMAT`: Join code is not 6 characters
- Generic errors for database or server issues

#### Usage Example
```javascript
import { getFunctions, httpsCallable } from 'firebase/functions';

const functions = getFunctions(app);
const lookupJoinCode = httpsCallable(functions, 'lookupJoinCode');

const result = await lookupJoinCode({ joinCode: 'ABC123' });
if (result.data.status === 'FOUND') {
  console.log(`Session ID: ${result.data.sessionId}`);
}
```

### `generateUniqueJoinCode`

A callable Cloud Function that generates a unique 6-character alphanumeric join code.

**Function Type:** `onCall`

#### Request Parameters
None required

#### Response
```javascript
{
  joinCode: "XYZ789",
  success: true
}
```

#### Error Handling
- Returns error if unable to generate a unique code after 10 attempts

#### Usage Example
```javascript
const generateUniqueJoinCode = httpsCallable(functions, 'generateUniqueJoinCode');

const result = await generateUniqueJoinCode();
console.log(`Generated join code: ${result.data.joinCode}`);
```

## Rate Limiting

The `lookupJoinCode` function implements rate limiting to prevent abuse:

- **Limit:** 20 requests per minute per IP address
- **Storage:** In-memory store (can be enhanced with Redis later)
- **Cleanup:** Automatic cleanup every 5 minutes to prevent memory leaks

## Security Considerations

1. **Rate Limiting**: Prevents brute force attacks on join codes
2. **Input Validation**: Join codes must be exactly 6 characters
3. **Case Insensitive**: All join codes are converted to uppercase for consistency
4. **Error Messages**: Generic error messages to prevent information disclosure

## Implementation Details

### Join Code Format
- 6 characters long
- Uppercase alphanumeric (A-Z, 0-9)
- Examples: `ABC123`, `XYZ789`, `A1B2C3`

### Database Structure
The function expects sessions to be stored in RTDB with this structure:
```javascript
{
  "sessions": {
    "session_123": {
      "state": {
        "joinCode": "ABC123"
      }
    }
  }
}
```

### Performance Optimizations
- Efficient IP address extraction from request headers
- Minimal database queries
- In-memory rate limiting for fast response times
- Automatic cleanup of old rate limit data

## Future Enhancements

1. **Redis Integration**: Replace in-memory store with Redis for distributed rate limiting
2. **App Check**: Enable Firebase App Check for additional security
3. **Analytics**: Add logging for join code usage analytics
4. **Caching**: Implement caching for frequently accessed sessions
5. **Batch Operations**: Support for batch join code lookups

## Testing

Use the provided `test-join-code.js` file to test the functions:

```bash
cd firebase/functions
node test-join-code.js
```

Make sure to set up Firebase emulators or use the actual Firebase project for testing.