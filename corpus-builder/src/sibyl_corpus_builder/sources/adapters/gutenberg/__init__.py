"""Project Gutenberg discovery, acquisition, and canonicalization adapter.

It resolves explicit author-search pages into reviewed work candidates, locates a preferred
plain-text artifact when needed, and removes only the recognized Gutenberg transport wrapper.
Network access is explicit. Registry approval, rights policy, artifact persistence, and later
corpus building remain outside this adapter."""
