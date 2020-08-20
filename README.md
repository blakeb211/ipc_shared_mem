"ipc_shared_mem" 

Simple demonstration of sending information between 2 processes using Win32 FileMapping to create a block of shared memory.

The block of shared memory is referred to as "Named Shared Memory" in the Microsoft literature because you assign a name to it. Both processes need to have this name to share the data.

When the process that created the memory exits, the block is freed and no longer accessible.

See image in this folder for a diagram of File Mapping.
