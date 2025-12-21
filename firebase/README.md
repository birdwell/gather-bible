# Gather Bible Firebase Backend

This directory contains the Firebase backend configuration for the Gather Bible app.

## Structure

```
firebase/
├── database.rules.json    # Realtime Database security rules
├── firebase.json          # Firebase project configuration
├── .firebaserc           # Firebase project aliases
├── functions/            # Cloud Functions
│   ├── index.js          # Main functions entry point
│   ├── package.json      # Functions dependencies
│   ├── .eslintrc.js      # ESLint configuration
│   └── .gitignore        # Functions-specific gitignore
└── README.md            # This file
```

## Setup

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Install dependencies in functions directory:
   ```bash
   cd functions
   npm install
   cd ..
   ```

4. Deploy functions:
   ```bash
   firebase deploy --only functions
   ```

5. Deploy database rules:
   ```bash
   firebase deploy --only database
   ```

## Database Security Rules

The security rules implement the following permissions:

- **State Management**: Only hosts can write to `/state`, but everyone can read
- **Participants**: Users can only write their own participant data, but everyone can read all participants
- **Host Management**: Only existing hosts can read the hosts list

## Cloud Functions

Currently implemented functions:

- `getSessionState`: Retrieves the current session state
- `addHost`: Adds a new host (should be protected in production)
- `joinSession`: Handles participant joining
- `leaveSession`: Handles participant leaving

## Development

To run functions locally:
```bash
firebase emulators:start --only functions
```

To test functions:
```bash
cd functions
npm test
```