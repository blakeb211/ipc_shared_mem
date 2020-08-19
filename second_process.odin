package ipc_shared_mem_second_process
// Demonstrate interprocess communications between 2 processes using the win32 api's 
// "named shared memory" IPC method.  

import "core:fmt"
import "core:path"
import "core:time"
import "core:os"
foreign import kern32 "kernel32.lib"
import win32 "core:sys/win32"
import win "core:sys/windows"

conv16_to_8 :: win32.utf16_to_utf8;
conv8_to_16 :: win32.utf8_to_utf16;

BUF_SIZE :: 256;
FILE_MAP_ALL_ACCESS :: 0xf001f;
szName : []u16 = conv8_to_16(`Global\MyFileMappingObject`);

main :: proc() {
	hMapFile : win.HANDLE;
	pBuf : win32.Wstring;

  hMapFile = OpenFileMappingW(
                   FILE_MAP_ALL_ACCESS,   // read/write access
                   false,                 // do not inherit the name
                   &szName[0]);           // name of mapping object

	if (hMapFile == nil)  {
		fmt.println("Could not create file mapping object");
		win.CloseHandle(hMapFile);
		win.ExitProcess(1);
	} else do fmt.println("File mapping object created successfully");

   pBuf = cast(win32.Wstring) MapViewOfFile(hMapFile, // handle to map object
               FILE_MAP_ALL_ACCESS,  									// read/write permission
               0,
               0,
               BUF_SIZE);

  if (pBuf == nil) { 
		fmt.println("Could not map view of file"); 
	  win.CloseHandle(hMapFile);
		win.ExitProcess(1);
	} else do fmt.println("Successfully mapped view of file to address");

	fmt.println("\n\nShared memory location READ by", path.name(os.args[0]), "=", win32.wstring_to_utf8(pBuf, BUF_SIZE));

	if UnmapViewOfFile(win.HANDLE(pBuf)) == true do fmt.println("Successfully unmapped view of file");
	else do fmt.println("Could not unmap view of file");
  
	win.CloseHandle(hMapFile);

	for i in 0..150_000 { 
		fmt.printf("."); 
		time.sleep(250 * time.Millisecond);
	}
}

// BINDINGS TO THE WIN32 C API
foreign import kernel32 "system:Kernel32.lib"
@(default_calling_convention="stdcall")
foreign kernel32 {
	CreateFileMappingW :: proc(hFile : win.HANDLE, 
	lpFileMapAttrib : win.LPSECURITY_ATTRIBUTES, 
	flProtect : win.DWORD, 
	dwMaxSizeHigh : win.DWORD,
	dwMaxSizeLow : win.DWORD,
	lpName : win.LPCWSTR) 
	-> win.HANDLE --- 

	MapViewOfFile :: proc(hFileMapObject : win.HANDLE, 
	dwDesiredAccess : win.DWORD, 
	dwFileOffsetHigh : win.DWORD,
	dwFileOffsetLow : win.DWORD, 
	dwNumberOfBytesToMap : win.SIZE_T)
	-> win.LPVOID ---

	UnmapViewOfFile :: proc(hFileMapObject : win.HANDLE) -> win.BOOL ---

	OpenFileMappingW :: proc(dwDesiredAccess : win.DWORD,   										// read/write access
                   				bInheritHandle : win.BOOL,          							// do not inherit the name
                   				lpFileMapName : win.LPCWSTR) -> win.HANDLE --- 	// name of mapping object
}
