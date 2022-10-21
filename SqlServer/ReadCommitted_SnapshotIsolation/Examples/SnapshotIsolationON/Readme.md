# General Overview
This is a general discussion and example on Read Committed Snapshot Isolation vs Snapshot Isolation and how the two differ using examples. 

Read Committed Snapshot Isolation
- No update conflicts
- Works with existing applications without requiring any change to the application
- Can be used with distributed transactions
- Provides statement-level read consistency

Snapshot Isolation
- Volnerable to update conflicts
- Application change may be required to use with an existing application
- Cannot be used with distributed transactions
- Provides transaction-level read consistency

# Processing steps
This example takes two sql files. 